module MatchSimHelper
  PLAYERS_ON_BENCH = 5
  GK = [2, 6]
  ALL_POS = [
      GK,
      [0, 5], [1, 5], [2, 5], [3, 5], [4, 5], # df
      [0, 4], [1, 4], [2, 4], [3, 4], [4, 4],
      [0, 3], [1, 3], [2, 3], [3, 3], [4, 3], # m
      [0, 2], [1, 2], [2, 2], [3, 2], [4, 2],
      [0, 1], [1, 1], [2, 1], [3, 1], [4, 1], # a
  ]
  # added to skill rolls
  BASE_SKILL = 9  # this means skill 1 relative to skill 9 is: 1+BASE_SKILL vs 9+BASE_SKILL

  MATCH_LENGTH_SECONDS = 270

  class PitchPos
    attr_reader :x, :y
    def initialize(x, y)
      @x = x
      @y = y
    end

    def to_a
      [@x, @y]
    end

    # Flip home coords to away coords
    def flip
      PitchPos.new(4 - @x, 6 - @y)
    end

    def self.dist(a,b)
      return Math.sqrt((a.x-b.x)**2 + (a.y-b.y)**2)
    end

    def to_s
      "#{@x},#{@y}"
    end
  end

  class TeamPos
    def initialize(positions)
      pos_pid_tuples = ALL_POS.map {|p|
        pitch_pos = PitchPos.new(p[0], p[1])
        pos = positions.find {|q| q.position_x == pitch_pos.x and q.position_y == pitch_pos.y }
        [pitch_pos, pos == nil ? nil : pos.player_id]
      }

      @by_string_lookup = pos_pid_tuples.map{|p| [p[0].to_s, p[1]]}.to_h
      @by_pos_lookup = pos_pid_tuples.to_h
    end

    def whos_at(pitch_pos)
      @by_string_lookup[pitch_pos.to_s]
    end

    def whos_at_exclude_gk(pitch_pos)
      if pitch_pos.x == 2 and pitch_pos.y == 6
        nil
      else
        @by_string_lookup[pitch_pos.to_s]
      end
    end

    def to_s
      @by_string_lookup.to_a.map{|i| [i[0].to_s, i[1]]}.to_s
    end

    def position_probability(pos)
      RngHelper.normalize_probability_list(
        @by_pos_lookup.to_a.map {|p|
          ppos, player_id = p
          if ppos.to_a == GK then
            # don't want to consider goalkeepers for random player selection
            [player_id, 0]
          else
            [player_id, 1.0 / (1.0+PitchPos.dist(ppos, pos)**2)]
          end
        }
      )
    end
  end

  class GameSimulator
    def initialize(game)
      @last_event = GameEvent.where(game_id: game.id).order(:time).reverse_order.first

      if @last_event == nil then
        # start of match. copy starting formation from teams
        game.home_formation = dup_starting_formation(game.home_team)
        game.away_formation = dup_starting_formation(game.away_team)
      end

      team0_players = game.home_formation.formation_pos.order(:position_num).all
      team1_players = game.away_formation.formation_pos.order(:position_num).all

      @game = game
      @teams = [game.home_team, game.away_team]
      @team_pos = [
        TeamPos.new(team0_players.take(11)),
        TeamPos.new(team1_players.take(11))
      ]
      @team_pids = [
        team0_players.map(&:player_id),
        team1_players.map(&:player_id),
      ]
      @player_by_id = ((team0_players + team1_players).map do |f|
        [f.player_id, f.player]
      end).to_h
    end

    def dup_starting_formation(team)
      players_pos = team.player_positions.all
      formation = team.formation.dup
      formation.save

      # note that starting11 may contain ineligible players
      starting11 = players_pos.take(11)
      possible_subs = players_pos.drop(11).select{|pos| pos.player.can_play?}

      # copy starting 11 positions, replacing ineligible players if possible
      starting11.each_index do |i|
        new_p = starting11[i].dup
        new_p.formation_id = formation.id
        if not new_p.player.can_play? then
          sub = possible_subs.shift  # we aren't picky
          if sub != nil then
            new_p.player = sub.player
            new_p.save
          else
            # don't save. we couldn't replace the player so we are short a player in the starting 11
          end
        else
          new_p.save
        end
      end

      possible_subs.take(PLAYERS_ON_BENCH).each do |s|
        new_p = s.dup
        new_p.formation_id = formation.id
        new_p.save
      end

      # goalkeeper has to exist :)
      gk = formation.positions_ordered.first
      if gk.position_x != GK[0] or gk.position_y != GK[1] then
        gk.update(position_x: GK[0], position_y: GK[1])
      end

      formation
    end

    def simulate_until(until_time)
      if until_time > @game.start + MATCH_LENGTH_SECONDS
        until_time = @game.start + MATCH_LENGTH_SECONDS
      end

      if until_time < @game.start
        return
      end

      while @last_event == nil or @last_event.time < until_time do
        simulate_tick()
      end

      if @last_event.time >= @game.start + MATCH_LENGTH_SECONDS
        @game.status = 'Played'
        @last_event = GameEvent.create(
          game_id: @game.id,
          kind: 'EndOfGame',
          side: RngHelper.dice(1,2) - 1,
          time: @last_event.time + 1,
          message: 'Full time!',
          ball_pos_x: @last_event.ball_pos_x,
          ball_pos_y: @last_event.ball_pos_y
        )
      else
        @game.status = 'InProgress'
      end
      @game.save
    end

    def ball_pos
      PitchPos.new(@last_event.ball_pos_x, @last_event.ball_pos_y)
    end

    def maybe_player_near(pos, side, tries=1)
      if side == 1 then pos = pos.flip end
      prob = @team_pos[side].position_probability(pos)

      result = nil
      for _ in 0...tries do
        p = RngHelper.sample_prob(prob)
        if p != nil then
          result = @player_by_id[p]
          break
        end
      end
      result
    end

    def player_near(pos, side, tries=1)
      p = maybe_player_near(pos, side, tries)
      if p then
        return p
      else
        gk = get_goalkeeper(side)
        while p == nil || p == gk
          # fall back to random player (but not GK)
          p = @player_by_id[@team_pids[side].sample]
        end
        return p
      end
    end

    def simulate_tick()
      @interesting_action = nil
      # kick off
      if @last_event == nil
        kick_off([0,1].sample)
      else
        if @last_event.kind == 'Goal'
          kick_off(1 - @last_event.side)
        elsif @last_event.kind == 'ShotMiss'
          goal_kick()
        elsif @last_event.kind == 'ShotSaved' and RngHelper.dice(1,2) == 1
          goal_kick()
        else
          normal_play()
        end
      end
    end

    def kick_off(side)
      @last_event = GameEvent.create(
        game_id: @game.id,
        kind: 'KickOff',
        side: side,
        time: @last_event == nil ? @game.start : @last_event.time + 1,
        message: 'Kick off!',
        ball_pos_x: 2,
        ball_pos_y: 3
      )
    end

    TRIES = 5

    def normal_play
      on_ball = player_near(self.ball_pos, @last_event.side, TRIES)
      defender = maybe_player_near(self.ball_pos, 1 - @last_event.side)

      if defender then
        if defense_success?(on_ball, defender) then
          emit_event("Boring", 1 - @last_event.side, self.ball_pos, msg_won_tackle(defender, on_ball), defender.id)
          return
        else
          @interesting_action = "evades #{defender.name}'s tackle"
        end
      end

      attacking_move(on_ball)
    end

    def defense_success?(on_ball, defender)
      side = @last_event.side
      RngHelper.dice(1, skill(side, on_ball, :handling, ball_pos)) <
      RngHelper.dice(1, skill(1-side, defender, :tackling, ball_pos))
    end

    # position of side's own goals
    def pos_of_goals(side)
      side == 0 ? PitchPos.new(2,6) : PitchPos.new(2,0)
    end

    def attacking_move(on_ball)
      side = @last_event.side
      dist_to_goals = 1.0 + PitchPos.dist(pos_of_goals(1 - side), ball_pos)

      options = []
      if dist_to_goals < 4.0 then
        options << [:shoot, 10 / dist_to_goals**2 ]
      end
      options << [:pass, 5.0 ]

      options = RngHelper.normalize_probability_list(options)
      action = RngHelper.sample_prob(options)

      case action
      when :shoot
        action_shoot(on_ball)
      when :pass
        action_pass(on_ball)
      else
        puts "ERROR: Unknown action in attacking_move: #{action.inspect}. Shouldn't happen..."
        emit_event("Boring", side, ball_pos, nil)
      end
    end

    def emit_event(kind, side, pos, msg, player_id=nil)
      @last_event = GameEvent.create(
        game_id: @game.id,
        kind: kind,
        side: side,
        time: @last_event.time + 1,
        message: msg,
        ball_pos_x: pos.x,
        ball_pos_y: pos.y,
        player_id: player_id
      )
    end

    def msg_won_tackle(defender, victim)
      ["%{d} wins the ball from %{v}",
       "Great tackle by %{d} to dispossess %{v}"]
      .sample % {d: defender.name, v: victim.name}
    end

    def msg_shoots(striker, goalkeeper)
      ["%{s} shoots!", "%{s} takes a shot!"]
      .sample % {s: striker.name, g: goalkeeper.name}
    end

    def msg_goal(striker, goalkeeper)
      ["Goal!! Great strike by %{s}!",
       "Goal!! %{s} scores a fantastic goal!",
      ].sample % {s: striker.name, g: goalkeeper.name}
    end

    def msg_shot_miss(striker, goalkeeper)
      ["It goes wide!",
       "Blasted over the bar!",
       "They'll be disappointed with that one",
       "It skims the crossbar!",
       "Off the post!"
      ].sample % {s: striker.name, g: goalkeeper.name}
    end

    def msg_shot_saved(striker, goalkeeper)
      ["Great save by %{g}",
       "Good save by %{g}",
       "%{g} barely reached that one!",
       "Nothing is getting past %{g} today!",
       "Comfortable save from %{g}"
      ].sample % {s: striker.name, g: goalkeeper.name}
    end

    def skill(side, player, type, position)
      if side == 1 then position = position.flip end
      s = player.method(type).call() + BASE_SKILL
      if player.get_positions.any?{|p|
        PitchPos.dist(
          PitchPos.new(p[0],p[1]),
          position
        ) <= 1.5
      } then
       # puts "#{player.name} in position! bonus"
        s += 2
      else
        #puts "#{player.name} out of position :( #{player.get_positions} vs #{position}"
      end
      s
    end

    def action_shoot(striker)
      side = @last_event.side
      dist_to_goals = PitchPos.dist(pos_of_goals(1 - side), ball_pos)
      # in attack position. try shot
      goalkeeper = get_goalkeeper(1 - side)

      raise "gk not on team" unless goalkeeper.team_id == @teams[1 - side].id
      raise "striker not on team" unless striker.team_id == @teams[side].id

      emit_event("ShotTry", side, ball_pos, msg_shoots(striker, goalkeeper), striker.id)

      if RngHelper.dice(1, skill(side, striker, :shooting, ball_pos) - dist_to_goals) >
         RngHelper.dice(1, skill(1-side, goalkeeper, :handling, ball_pos) + skill(1-side, goalkeeper, :speed, ball_pos))
        emit_event("Goal", side, ball_pos, msg_goal(striker, goalkeeper), striker.id)
        if side == 0
          @game.home_goals += 1
        else
          @game.away_goals += 1
        end
      else
        if RngHelper.dice(1,2) == 1 then
          emit_event("ShotMiss", side, ball_pos, msg_shot_miss(striker, goalkeeper), striker.id)
        else
          # note that side = striker's team, not GK's team
          emit_event("ShotSaved", side, ball_pos, msg_shot_saved(striker, goalkeeper), striker.id)
        end
      end
    end

    def clamp_y(y)
      y > 0 ? (y < 6 ? y : 6) : 0
    end
    
    def action_pass(on_ball)
      side = @last_event.side

      dir = side == 0 ? [-2,-1,0,1].sample : [-1,0,1,2].sample

      # find new position
      new_pos = PitchPos.new((0..4).to_a.sample, clamp_y(ball_pos.y + dir))

      defender = maybe_player_near(new_pos, 1 - side, 2)
      
      if defender != nil && interception_success?(on_ball, defender) then
        emit_event("Boring", 1 - side, new_pos, "#{defender.name} intercepts #{on_ball.name}'s pass", defender.id)
      else
        if @interesting_action != nil then
          msg = "#{on_ball.name} #{@interesting_action}"
        else
          msg = nil
        end
        emit_event("Boring", side, new_pos, msg, on_ball.id)
      end
    end

    def interception_success?(on_ball, defender)
      side = @last_event.side
      RngHelper.dice(1, skill(side, on_ball, :passing, ball_pos)) <
      RngHelper.dice(1, skill(1-side, defender, :handling, ball_pos))
    end

    def get_goalkeeper(side)
      @player_by_id[@team_pos[side].whos_at(PitchPos.new(GK[0], GK[1]))]
    end

    def goal_kick
      side = 1 - @last_event.side
      goalkeeper = get_goalkeeper(side)
      pos = PitchPos.new((0..4).to_a.sample, 3)
      emit_event("Boring", side, pos, "Goal kick by #{goalkeeper.name}")
    end
  end
end
