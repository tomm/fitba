module MatchSimHelper
  SECONDS_PER_TICK = 1
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
  BASE_SKILL = 5  # this means skill 1 relative to skill 9 is: 1+BASE_SKILL vs 9+BASE_SKILL

  MATCH_LENGTH_SECONDS = 270

  class PitchPos
    attr_accessor :x, :y
    def initialize(x, y)
      @x = x
      @y = y
    end

    def to_a
      [@x, @y]
    end

    def ==(other)
      @x == other.x && @y == other.y
    end

    # Flip home coords to away coords
    def flip
      PitchPos.new(4 - @x, 6 - @y)
    end

    def self.dist(a,b)
      return [(a.x-b.x).abs, (a.y-b.y).abs].max
    end

    def to_s
      "#{@x},#{@y}"
    end

    def clamp_outfield
      @y = y > 1 ? (y < 5 ? y : 5) : 1
      @x = x > 0 ? (x < 5 ? x : 4) : 0
    end
  end

  class PlayerPos
    attr_reader :player, :pos
    def initialize(position_po, side)
      @player = position_po.player
      @pos = PitchPos.new(position_po.position_x, position_po.position_y)
      @side = side

      if not (@pos.x == GK[0] and @pos.y == GK[1]) then
        # random jiggle to player positions
        @pos.x += RngHelper.int_range(-1,1)
        @pos.y += RngHelper.int_range(-1,1)
        @pos.clamp_outfield
      end

      if side == 1 then
        @pos = @pos.flip
      end
    end
  end

  KICKOFF_POS = PitchPos.new(2,3)

  class GameSimulator
    def initialize(game)
      @last_event = GameEvent.where(game_id: game.id)
                             .order(:time).reverse_order.first

      if @last_event == nil then
        # start of match. copy starting formation from teams
        game.home_formation = dup_starting_formation(game.home_team)
        game.away_formation = dup_starting_formation(game.away_team)
      end

      team0_players = game.home_formation.formation_pos.order(:position_num).all
      team1_players = game.away_formation.formation_pos.order(:position_num).all

      @game = game
      @teams = [game.home_team, game.away_team]
      @squad = [
        team0_players.take(11).map{|p| PlayerPos.new(p, 0)},
        team1_players.take(11).map{|p| PlayerPos.new(p, 1)}
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
        emit_event('EndOfGame', @last_event.side, ball_pos, "Full time!", @last_event.player_id)
        media_response
      else
        @game.status = 'InProgress'
      end
      @game.save
    end

    def media_response
      raise "media_response called when game not ended" unless @game.status == 'Played'
      goal_diff = @game.home_goals - @game.away_goals
      if goal_diff.abs > 4 then
        loser = if goal_diff < 0 then @game.home_team else @game.away_team end
        winner = if goal_diff > 0 then @game.home_team else @game.away_team end
        loser_goals = if goal_diff < 0 then @game.home_goals else @game.away_goals end
        winner_goals = if goal_diff > 0 then @game.home_goals else @game.away_goals end

        participle = ["spanked", "crushed", "humiliated", "destroyed", "trounced"]
        game_descriptions = ["drubbing", "whipping", "meltdown", "shambles", "thrashing"]

        if RngHelper.dice(1,2) == 1 then
          # focus on loser
          NewsArticle.create(title: "#{loser.name} #{participle.sample} by #{winner.name} in #{winner_goals}:#{loser_goals} #{game_descriptions.sample}",
                             body: "",
                             date: Time.now)
        else
          # focus on winner
          NewsArticle.create(title: "#{winner.name} in #{winner_goals}:#{loser_goals} #{game_descriptions.sample} of #{loser.name}",
                             body: "",
                             date: Time.now)
        end
      end
    end

    def ball_pos
      PitchPos.new(@last_event.ball_pos_x, @last_event.ball_pos_y)
    end

    def players_at(pos, side)
      @squad[side].select{|p| p.pos == pos}.map(&:player)
    end

    def random_player(side)
      # not GK
      @squad[side].drop(1).sample.player
    end

    def must_have_player_here(side, pos)
      random_player(side)
    end

    #: () -> [side, player]
    def any_team_receiver(pos)
      players = players_at(pos, 0).map{|p| [0, p]} +
                players_at(pos, 1).map{|p| [1, p]}

      if players.size == 0 then
        players << [0, random_player(0)]
        players << [1, random_player(1)]
      end

      players.sample
    end

    def simulate_tick()
      # kick off
      if @last_event == nil
        kick_off([0,1].sample)
      else
        if @last_event.kind == 'Goal'
          kick_off(1 - @last_event.side)
        elsif @last_event.kind == 'ShotMiss'
          goal_kick()
        elsif @last_event.kind == 'ShotSaved'
          # goalkeeper controls it
          goal_kick()
        else
          normal_play()
        end
      end
    end

    def kick_off(side)
      pos = PitchPos.new(2,3)
      player = must_have_player_here(side, pos)
      if @last_event == nil then
        # kickoff at beginning of game
        @last_event = GameEvent.create(
          game_id: @game.id,
          kind: 'KickOff',
          side: side,
          time: @last_event == nil ? @game.start : @last_event.time + SECONDS_PER_TICK,
          player_id: player.id,
          message: 'Kick off!',
          ball_pos_x: pos.x,
          ball_pos_y: pos.y
        )
      else
        emit_event('KickOff', side, pos, 'Kick off!', player.id)
      end
    end

    def normal_play
      on_ball = @player_by_id[@last_event.player_id]

      defenders = players_at(self.ball_pos, 1 - @last_event.side)

      defenders.each{|defender|
        if defense_success?(on_ball, defender) then
          emit_event("Boring", 1 - @last_event.side, self.ball_pos, msg_won_tackle(defender, on_ball), defender.id)
          # allow normal_play to continue with other side in control. this prevents loops
          # of tackling on one pitch position
          on_ball = defender
          break
        end
      }

      attacking_move(on_ball)
    end

    def defense_success?(on_ball, defender)
      side = @last_event.side
      RngHelper.dice(4, skill(side, on_ball, :handling, ball_pos)) <=
      RngHelper.dice(4, skill(1-side, defender, :tackling, ball_pos))
    end

    # position of side's own goals
    def pos_of_goals(side)
      side == 0 ? PitchPos.new(2,6) : PitchPos.new(2,0)
    end

    def attacking_move(on_ball)
      side = @last_event.side
      dist_to_goals = 1.0 + PitchPos.dist(pos_of_goals(1 - side), ball_pos)
      pass_to = ai_pass_target(on_ball)

      options = []
      if dist_to_goals < 4.0 then
        options << [:shoot, 20 / dist_to_goals**2 ]
      end

      if pass_to != nil then
        options << [:pass, 5.0 ]
      end

      if (side == 0 && ball_pos.y > 1) ||
         (side == 1 && ball_pos.y < 5) then
        options << [:run, 5.0 ]
      end

      options = RngHelper.normalize_probability_list(options)
      action = RngHelper.sample_prob(options)

      case action
      when :shoot
        action_shoot(on_ball)
      when :pass
        action_pass(on_ball, pass_to)
      when :run
        action_run(on_ball)
      else
        Rails.logger.error "ERROR: Unknown action in attacking_move: #{action.inspect}. Shouldn't happen..."
        emit_event("Boring", side, ball_pos, nil, on_ball.id)
      end
    end

    def emit_event(kind, side, pos, msg, player_id)
      @last_event = GameEvent.create(
        game_id: @game.id,
        kind: kind,
        side: side,
        time: @last_event.time + SECONDS_PER_TICK,
        message: msg,
        ball_pos_x: pos.x,
        ball_pos_y: pos.y,
        player_id: player_id
      )
    end

    def msg_won_tackle(defender, victim)
      ["%{d} wins the ball from %{v}",
       "Good tackle from %{d}",
       "Great tackle by %{d} to dispossess %{v}"]
      .sample % {d: defender.name, v: victim.name}
    end

    def msg_dispossession(defender, victim)
      ["Strong challenge from %{d}",
       "%{d} outpaces %{v}",
       "%{v} can't find a way past %{d}",
       "%{d} puts a stop to %{v}'s run"
      ].sample % {d: defender.name, v: victim.name}
    end

    def msg_run(on_ball, from, to)
      if (from.x == 0 and to.x == 0) ||
         (from.x == 4 and to.x == 4) then
        # run down the wing
        ["%{p} makes a run down the wing",
         "%{p} charges down the wing",
         "%{p} takes it down the wing"
        ].sample % {p: on_ball.name}
      else
        ["%{p} makes a forward run",
         "%{p} runs at the defence",
         "%{p} find a way through",
        ].sample % {p: on_ball.name}
      end
    end

    def msg_shoots(striker, goalkeeper)
      ["%{s} shoots!",
       "%{s} takes a shot!",
       "%{s} fires one at %{g}!"
      ].sample % {s: striker.name, g: goalkeeper.name}
    end

    def msg_goal(striker, goalkeeper)
      ["Goal!! Great strike by %{s}!",
       "Goal!! %{s} scores a fantastic goal!",
       "Goal!! Incredible strike by %{s}!",
      ].sample % {s: striker.name, g: goalkeeper.name}
    end

    def msg_shot_miss(striker, goalkeeper)
      ["It goes wide!",
       "Blasted over the bar!",
       "They'll be disappointed with that one",
       "It skims the crossbar!",
       "It soars into the stands",
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

    def msg_pass(from, to)
      ["%{from} passes to %{to}",
       "%{from} finds %{to}"
      ].sample % {from: from.name, to: to.name}
    end

    def msg_interception(victim, interceptor)
      ["%{i} intercepts %{v}'s pass",
       "%{i} reads %{v}'s pass",
       "%{i} picks up a sloppy pass by %{v}"
      ].sample % {i: interceptor.name, v: victim.name}
    end

    def skill(side, player, type, position)
      if side == 1 then position = position.flip end
      s = player.method(type).call() + BASE_SKILL + player.form
      if player.get_positions.include? position.to_a then
        #puts "#{player.name} in position! bonus"
        s += 2
      else
        #puts "#{player.name} out of position :( #{player.get_positions} vs #{position}"
      end
      s
    end

    def action_shoot(striker)
      side = @last_event.side
      shot_from = ball_pos
      goals_pos = pos_of_goals(1 - side)
      dist_to_goals = PitchPos.dist(goals_pos, ball_pos)
      # in attack position. try shot
      goalkeeper = get_goalkeeper(1 - side)

      raise "gk not on team" unless goalkeeper.team_id == @teams[1 - side].id
      raise "striker not on team" unless striker.team_id == @teams[side].id

      emit_event("ShotTry", side, ball_pos, msg_shoots(striker, goalkeeper), striker.id)

      # this is carefully tuned so simulate before fucking with it
      if RngHelper.dice(3, skill(side, striker, :shooting, ball_pos)) >
         RngHelper.dice(3, 5 + 5*dist_to_goals) +
         RngHelper.dice(1, skill(1-side, goalkeeper, :handling, goals_pos)) +
         RngHelper.dice(1, skill(1-side, goalkeeper, :speed, goals_pos)) then
         emit_event("Goal", side, goals_pos, msg_goal(striker, goalkeeper), striker.id)
        if side == 0
          @game.home_goals += 1
        else
          @game.away_goals += 1
        end
      else
        if RngHelper.dice(1,2) == 1 then
          emit_event("ShotMiss", 1 - side, goals_pos, msg_shot_miss(striker, goalkeeper), striker.id)
        else
          emit_event("ShotSaved", 1 - side, goals_pos, msg_shot_saved(striker, goalkeeper), goalkeeper.id)
        end
      end
    end

    # () -> PlayerPos
    def ai_pass_target(on_ball)
      side = @last_event.side

      # pass to anyone upfield
      @squad[side].drop(1).select{|p|
        p.player.id != on_ball.id &&
        (
          (side == 0 && p.pos.y <= ball_pos.y) ||
          (side == 1 && p.pos.y >= ball_pos.y)
        )
      }.sample
    end

    def action_run(on_ball)
      side = @last_event.side
      old_pos = ball_pos

      new_pos = PitchPos.new(
        old_pos.x + RngHelper.int_range(-1,1),
        if side == 0 then old_pos.y - 1 else old_pos.y + 1 end)
      new_pos.clamp_outfield
      defenders = players_at(new_pos, 1 - side)

      defenders.each {|defender|
        if RngHelper.dice(4, skill(side, on_ball, :handling, new_pos)) +
           RngHelper.dice(4, skill(side, on_ball, :speed,    new_pos)) <
           RngHelper.dice(4, skill(1-side, defender, :tackling, new_pos)) +
           RngHelper.dice(4, skill(1-side, defender, :speed, new_pos)) 
        then
          msg = msg_dispossession(defender, on_ball)
          emit_event("Boring", side, old_pos, msg, on_ball.id)
          emit_event("Boring", 1 - side, new_pos, msg, defender.id)
          return
        end
      }
      msg = msg_run(on_ball, old_pos, new_pos)
      emit_event("Boring", side, old_pos, msg, on_ball.id)
      emit_event("Boring", side, new_pos, msg, on_ball.id)
    end
    
    def action_pass(on_ball, pass_to)
      side = @last_event.side

      old_pos = ball_pos
      new_pos = pass_to.pos
      receiver = pass_to.player
      defenders = players_at(new_pos, 1 - side)
      dist = PitchPos.dist(old_pos, new_pos)

      raise "can't pass to self" unless on_ball != receiver

      defenders.each {|defender|
        if RngHelper.dice(8, skill(side, on_ball, :passing, old_pos)) +
           RngHelper.dice(4, skill(side, receiver, :handling, new_pos)) -
           dist*dist <
           RngHelper.dice(4, skill(1-side, defender, :handling, new_pos)) +
           RngHelper.dice(4, skill(1-side, defender, :speed, new_pos))
        then
          msg = msg_interception(on_ball, defender)
          emit_event("Boring", side,     old_pos, msg, on_ball.id)
          emit_event("Boring", 1 - side, new_pos, msg, defender.id)
          return
        end
      }
      
      msg = msg_pass(on_ball, receiver)
      emit_event("Boring", side, old_pos, msg, on_ball.id)
      emit_event("Boring", side, new_pos, msg, receiver.id)
    end

    def get_goalkeeper(side)
      @squad[side][0].player
    end

    def goal_kick
      side = @last_event.side
      goalkeeper = get_goalkeeper(side)
      pos = PitchPos.new((0..4).to_a.sample, 3)
      new_side, player = any_team_receiver(pos)
      emit_event("Boring", side, pos, "Goal kick by #{goalkeeper.name}", goalkeeper.id)
      emit_event("Boring", new_side, pos, "#{player.name} in possession", player.id)
    end
  end
end
