require_relative './push_notification_helper'

module MatchSimHelper
  MAX_SUBSTITUTIONS = 3
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

  MATCH_PERIODS = [
    [0, 3*45],  # first half
    [3*55, 3*100], # second half
    [3*105, 3*120], # first half extra time
    [3*125, 3*140] # second half extra time
  ]

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
    attr_reader :player, :pos, :side, :position_po
    def initialize(position_po, side)
      @player = position_po.player
      @position_po = position_po
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
      @game = game
      @last_event = GameEvent.where(game_id: game.id)
                             .order(:time).reverse_order.first

      if @last_event == nil then
        # start of match. copy starting formation from teams
        game.home_formation = dup_starting_formation(game.home_team)
        game.away_formation = dup_starting_formation(game.away_team)
      end

      reload_squad()
    end

    def reload_squad
      team0_players = @game.home_formation.formation_pos.order(:position_num).all
      team1_players = @game.away_formation.formation_pos.order(:position_num).all

      @teams = [@game.home_team, @game.away_team]
      @squad = [
        team0_players.take(11).map{|p| PlayerPos.new(p, 0)},
        team1_players.take(11).map{|p| PlayerPos.new(p, 1)}
      ]
      @subs = [
        team0_players.drop(11),
        team1_players.drop(11)
      ]

      exclude_ineligible_players()

      @team_pids = [
        team0_players.map(&:player_id),
        team1_players.map(&:player_id),
      ]
      @player_by_id = ((team0_players + team1_players).map do |f|
        [f.player_id, f.player]
      end).to_h
    end

    def exclude_ineligible_players
      # note we filter out ineligible players again (dup_starting_formation did it too).
      # this is because injuries and send-offs could have happened
      @squad.each{|s| s.select!{|pos| pos.player.can_play?}}
      @subs.each{|s| s.select!{|pos| pos.player.can_play?}}
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

    def match_draws_allowed
      @game.league.kind != "Cup"
    end

    def period_we_are_in(time)
      start = @game.start
      period = 0
      ended = true

      MATCH_PERIODS.each_with_index{|p,i|
        period = i
        if time < start + p[0] then
          # this period just ended
          period = i-1
          break
        elsif time >= start + p[0] and time <= start + p[1] then
          ended = false
          break
        end
      }
      [period, ended]
    end

    def end_game(reason: "Full time!")
      @game.status = 'Played'
      if @last_event == nil then
        emit_event('EndOfGame', 0, PitchPos.new(2,3), reason, nil)
      else
        emit_event('EndOfGame', @last_event.side, ball_pos, reason, @last_event.player_id)
      end
      media_response
      #pay_match_income
      PushNotificationHelper.send_result_notifications(@game)
    end

    def test_match_abandonment
      if @squad[0].size < 7 then
        @game.home_goals = 0
        @game.away_goals = 3
        end_game(reason: "Match abandoned because #{@teams[0].name} cannot field enough players.")
        return true
      elsif @squad[1].size < 7 then
        @game.home_goals = 3
        @game.away_goals = 0
        end_game(reason: "Match abandoned because #{@teams[1].name} cannot field enough players.")
        return true
      else
        return false
      end
    end

    def simulate_until(until_time)

      if until_time < @game.start
        return
      end

      while @last_event == nil or @last_event.time <= until_time do
        if test_match_abandonment() then
          break
        end

        simulate_tick()

        if @last_event.kind == 'Boring' then
          spawn_injury()
        end

        period, ended = period_we_are_in(@last_event.time)
        is_level = @game.home_goals == @game.away_goals

        # a period ended
        if ended then
          if (period == 1 and (match_draws_allowed or not is_level)) then
            # game ends after normal time
            end_game()
            break
          elsif period == 3 then
            # game ends after extra time (maybe with penalties)
            if is_level then
              # penalties
              penalty_shootout
            end
            end_game()
            break
          else
            # end of a half
            period_name = ["The first half", "Normal time", "The first half of extra time"][period]
            msg = "#{period_name} ends with the teams at #{@game.home_goals}:#{@game.away_goals}"
            emit_event('EndOfPeriod', @last_event.side, ball_pos, msg, nil)
            emit_event('EndOfPeriod', @last_event.side, ball_pos, msg, nil)
            @last_event.update(time: @game.start + MATCH_PERIODS[period+1][0])
          end
        else
          @game.status = 'InProgress'
        end
      end

      @game.save
    end

    # maybe spawn injuries. do substutions as necessary
    def spawn_injury
      if rand < 0.004 then
        side = RngHelper.int_range(0,1)
        victim = @squad[side][RngHelper.int_range(0,10)]

        if victim != nil and
          # <- don't injure the on-the-ball player. game engine can't deal with that yet
          victim.player.id != @last_event.player_id then

          PlayerHelper.spawn_injury_on_player(victim.player, how: "during our match against #{@teams[1-side].name}")
          exclude_ineligible_players()
          emit_event('Injury', @last_event.side, ball_pos, "#{victim.player.name} is injured!", @last_event.player_id)
        end
      end
    end

    def ai_substitutions
      # Currently only does subs when there is an injured player
      team0_players_injured = @game.home_formation.formation_pos.order(:position_num).limit(11).all.select{|p| not p.player.can_play?}
      team1_players_injured = @game.away_formation.formation_pos.order(:position_num).limit(11).all.select{|p| not p.player.can_play?}

      team0_players_injured.each{|formation_pos|
        try_substitute_player(0, formation_pos)
      }
      team1_players_injured.each{|formation_pos|
        try_substitute_player(1, formation_pos)
      }
    end

    def try_substitute_player(side, formation_pos)
      if @game.subs_used(side) < MAX_SUBSTITUTIONS and @subs[side].size > 0 then
        substitute_out_player(side, formation_pos)
      else
        #puts "Team #{side} has used all subs or has none available"
      end
    end

    def substitute_out_player(side, formation_pos)
      # no logic. choose randomly from available players
      sub = @subs[side].sample
      raise "Expected there to be subs..." unless sub != nil
      #puts "Team #{side}: Subbing on #{sub.player.name} for #{formation_pos.player.name}"
      emit_event('Sub', side, ball_pos, "#{sub.player.name} will come on to replace #{formation_pos.player.name}", nil)
      p = formation_pos.player
      formation_pos.update(player: sub.player)
      sub.update(player: p)

      @game.use_sub(side)
      @game.save

      reload_squad()
    end

    def penalty_shootout
      takers0 = @squad[0].sort_by{|p| -p.player.shooting}
      takers1 = @squad[1].sort_by{|p| -p.player.shooting}
      gk0 = get_goalkeeper(0)
      gk1 = get_goalkeeper(1)

      emit_event('Boring', 0, ball_pos, "It will be decided by penalties!", nil)

      to_go = 5
      scored = [0,0]

      while (scored[0]-scored[1]).abs <= to_go do
        scored[0] += penalty(0, takers0.first.player, gk1, is_shootout: true)
        scored[1] += penalty(1, takers1.first.player, gk0, is_shootout: true)
        takers0.rotate!
        takers1.rotate!
        if to_go > 0 then to_go -= 1 end

        emit_event('Boring', 0, ball_pos, "Penalties: #{scored[0]}:#{scored[1]}", nil)
      end

      winner = if scored[0] > scored[1] then @game.home_team else @game.away_team end
      emit_event('Boring', 0, ball_pos, "#{winner.name} win #{scored[0]}:#{scored[1]} on penalties!", nil)

      @game.home_penalties = scored[0]
      @game.away_penalties = scored[1]
    end

    def penalty(side, taker, gk, is_shootout: false)
      emit_event('Boring', side, PitchPos.new(2,5), "#{taker.name} steps up to penalty spot", taker.id)
      emit_event('Boring', side, PitchPos.new(2,5), "#{taker.name} shoots!", taker.id)

      if RngHelper.dice(4, skill(0, taker, :shooting, PitchPos.new(2,1))) <=
          RngHelper.dice(2, skill(1, gk, :speed, PitchPos.new(2,0))) +
          RngHelper.dice(1, skill(1, gk, :handling, PitchPos.new(2,0)))
      then
        emit_event('Boring', 1-side, PitchPos.new(2,6), "Fantastic dive by #{gk.name} to deny #{taker.name}", gk.id)
        0
      else
        kind = if is_shootout then 'Boring' else 'Goal' end
        emit_event(kind, side, PitchPos.new(2,6), "Goal! Great penalty by #{taker.name}", taker.id)
        1
      end
    end

    def pay_match_income
      team0_players = @game.home_formation.formation_pos.order(:position_num).all.take(11)
      team1_players = @game.away_formation.formation_pos.order(:position_num).all.take(11)

      total_skill = team0_players.map(&:player).map(&:skill).sum + team1_players.map(&:player).map(&:skill).sum

      # for 2 teams of avg 9 skill total skill = 990
      # for such a game we try to give ~3M income

      income = 2500*total_skill + (rand()*1000*total_skill).to_i
      puts "Paying match income of #{income} to #{@game.home_team.name}"
      @game.home_team.update!(money: @game.home_team.money + income)
      AccountItem.create!(
        description: 'Game income',
        amount: income,
        season: SeasonHelper.current_season,
        team_id: @game.home_team.id
      )
    end

    def media_response
      raise "media_response called when game not ended" unless @game.status == 'Played'
      goal_diff = @game.home_goals - @game.away_goals
      if goal_diff.abs > 4 then
        winner, loser = @game.winner_loser
        loser_goals = if goal_diff < 0 then @game.home_goals else @game.away_goals end
        winner_goals = if goal_diff > 0 then @game.home_goals else @game.away_goals end

        participle = ["spanked", "crushed", "humiliated", "destroyed", "trounced"]
        lose_game_descriptions = ["drubbing", "whipping", "meltdown", "shambles", "thrashing"]
        win_gerund = ["drubbing", "whipping", "thrashing", "humiliation"]

        if RngHelper.dice(1,2) == 1 then
          # focus on loser
          NewsArticle.create(title: "#{loser.name} #{participle.sample} by #{winner.name} in #{winner_goals}:#{loser_goals} #{lose_game_descriptions.sample}",
                             body: "",
                             date: Time.now)
        else
          # focus on winner
          NewsArticle.create(title: "#{winner.name} in #{winner_goals}:#{loser_goals} #{win_gerund.sample} of #{loser.name}",
                             body: "",
                             date: Time.now)
        end
      end

      if @game.stage == 1 then
        winner, loser = @game.winner_loser
        NewsArticle.create(title: "#{winner.name} win the #{@game.league.name}!",
                           body: "",
                           date: Time.now)
      end
    end

    def ball_pos
      PitchPos.new(@last_event.ball_pos_x, @last_event.ball_pos_y)
    end

    def players_at(pos, side)
      @squad[side].select{|p| p.pos == pos}
    end

    # excludes GK
    def players_within_distance(pos, distance, side)
      @squad[side].drop(1).select{|p| PitchPos.dist(p.pos, pos) <= distance}
    end

    def random_player(side)
      # not GK
      @squad[side].drop(1).sample
    end

    def must_have_player_here(side, pos)
      random_player(side)
    end

    #: () -> [side, player]
    def any_team_receiver(pos)
      players = players_at(pos, 0) +
                players_at(pos, 1)

      if players.size == 0 then
        players << random_player(0)
        players << random_player(1)
      end

      players.sample
    end

    def simulate_tick()
      # kick off
      if @last_event == nil
        kick_off([0,1].sample)
      else
        # store this since ai_substitutions might hose the @last_event
        side = @last_event.side
        if @last_event.kind == 'Goal'
          ai_substitutions()
          kick_off(1 - side)
        elsif @last_event.kind == 'EndOfPeriod'
          ai_substitutions()
          kick_off([0,1].sample)  # XXX should be alternating sides...
        elsif @last_event.kind == 'Corner'
          ai_substitutions()
          corner(side)
        elsif @last_event.kind == 'GoalKick'
          ai_substitutions()
          goal_kick(side)
        elsif @last_event.kind == 'ShotSaved'
          ai_substitutions()
          # goalkeeper controls it
          goal_kick(side)
        else
          normal_play()
        end
      end
    end

    def kick_off(side)
      pos = PitchPos.new(2,3)
      player = must_have_player_here(side, pos).player
      emit_event('KickOff', side, pos, 'Kick off!', player.id)
    end

    def normal_play
      on_ball = @player_by_id[@last_event.player_id]
      raise "On ball player is nil in game #{@game.id}! FUCK" unless on_ball != nil

      defenders = players_at(self.ball_pos, 1 - @last_event.side)

      defenders.each{|defender|
        if defense_success?(on_ball, defender.player) then
          emit_event("Boring", 1 - @last_event.side, self.ball_pos, msg_won_tackle(defender.player, on_ball), defender.player.id)
          # allow normal_play to continue with other side in control. this prevents loops
          # of tackling on one pitch position
          on_ball = defender.player
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

    def corner(side)
      # .drop(1) disallows GK
      kicker = @squad[side].drop(1).sort_by{|p| -p.player.passing}.first

      corner_pos = PitchPos.new([0,4].sample, side == 0 ? 0 : 6)
      target_pos = PitchPos.new(2, side == 0 ? 1 : 5)
      kick_quality = RngHelper.dice(2, skill(side, kicker.player, :passing, corner_pos))

      emit_event("Boring", side, corner_pos, msg_corner_take(kicker.player), kicker.player.id)
      emit_event("Boring", side, target_pos, msg_corner_take(kicker.player), kicker.player.id)
      
      players = players_within_distance(target_pos, 2, side) +
                players_within_distance(target_pos, 2, 1 - side)
      winner = players.sort_by{|p|
        if p.side == side then
          -kick_quality - 
           (RngHelper.dice(3, skill(p.side, p.player, :handling, target_pos)) +
            RngHelper.dice(3, skill(p.side, p.player, :speed, target_pos)))
        else
          -(RngHelper.dice(4, skill(p.side, p.player, :handling, target_pos)) +
            RngHelper.dice(4, skill(p.side, p.player, :speed, target_pos)))
        end
      }.first

      # should never come to this, because players will be within distance above ^^
      if winner == nil then winner = any_team_receiver(target_pos) end

      if winner.side == side then
        # shoot
        action_shoot(winner.player, in_air: true)
        return
      else
        # clearance
        msg = msg_clearance(winner.player)
        emit_event("Boring", 1-side, target_pos, msg, winner.player.id)
        anyone_grab_ball(PitchPos.new(RngHelper.int_range(0,4),
                                      side == 0 ?  target_pos.y + 1 : target_pos.y - 1))
        return
      end
    end

    # position of side's own goals
    def pos_of_goals(side)
      side == 0 ? PitchPos.new(2,6) : PitchPos.new(2,0)
    end

    def is_attacking_wing(side, pos)
      if pos.x != 0 and pos.x != 4 then
        false
      elsif side == 0 and pos.y == 1 then
        true
      elsif side == 1 and pos.y == 5 then
        true
      else
        false
      end
    end

    def ai_cross_targets(on_ball, pos)
      side = @last_event.side
      if not is_attacking_wing(side, pos) then
        []
      else
        players_at(PitchPos.new(1,pos.y), side) +
        players_at(PitchPos.new(2,pos.y), side) +
        players_at(PitchPos.new(3,pos.y), side)
      end
    end

    def attacking_move(on_ball)
      side = @last_event.side
      dist_to_goals = 1.0 + PitchPos.dist(pos_of_goals(1 - side), ball_pos)
      pass_to = ai_pass_target(on_ball)
      cross_to = ai_cross_targets(on_ball, ball_pos)

      options = []
      if dist_to_goals < 4.0 then
        options << [:shoot, 20 / dist_to_goals**2 ]
      end

      if pass_to != nil then
        options << [:pass, 5.0 ]
      end

      if cross_to != [] then
        options << [:cross, 40 ]
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
      when :cross
        action_cross(on_ball, cross_to)
      else
        Rails.logger.error "ERROR: Unknown action in attacking_move: #{action.inspect}. Shouldn't happen..."
        emit_event("Boring", side, ball_pos, nil, on_ball.id)
      end
    end

    def action_cross(on_ball, cross_targets)
      side = @last_event.side
      target = cross_targets.sample
      kick_quality = RngHelper.dice(2, skill(side, on_ball, :passing, ball_pos))

      msg = msg_cross(on_ball, target.player)
      emit_event("Boring", side, ball_pos, msg, on_ball.id)
      emit_event("Boring", side, target.pos, msg, on_ball.id)
      
      players = players_at(target.pos, 1-side)
      players << target

      winner = players.sort_by{|p|
        if p.side == side then
          -kick_quality - 
            (RngHelper.dice(3, skill(p.side, p.player, :handling, target.pos)) +
             RngHelper.dice(3, skill(p.side, p.player, :speed, target.pos)))
        else
          -(RngHelper.dice(4, skill(p.side, p.player, :handling, target.pos)) +
            RngHelper.dice(4, skill(p.side, p.player, :speed, target.pos)))
        end
      }.first

      if winner.side == side then
        # shoot
        action_shoot(winner.player, in_air: true)
      else
        # clearance
        msg = msg_clearance(winner.player)
        emit_event("Boring", 1-side, target.pos, msg, winner.player.id)
        anyone_grab_ball(PitchPos.new(RngHelper.int_range(0,4),
                                      side == 0 ?  target.pos.y + 1 : target.pos.y - 1))
      end
    end

    def emit_event(kind, side, pos, msg, player_id)
      @last_event = GameEvent.create(
        game_id: @game.id,
        kind: kind,
        side: side,
        time: @last_event == nil ? @game.start : @last_event.time + SECONDS_PER_TICK,
        message: msg,
        ball_pos_x: pos.x,
        ball_pos_y: pos.y,
        player_id: player_id
      )
    end

    def msg_clearance(kicker)
      ["%{p} with the clearance",
       "A rushed clearance from %{p}",
       "%{p} heads it out of the danger zone"
      ].sample % {p: kicker.name}
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

    def msg_shoots(striker, goalkeeper, in_air: false)
      if in_air == true then
        ["%{s} heads it towards goal!",
         "%{s} with a driving header!",
         "%{s} flicks it towards goal!"
        ].sample % {s: striker.name, g: goalkeeper.name}
      else
        ["%{s} shoots!",
         "%{s} takes a shot!",
         "%{s} fires one at %{g}!"
        ].sample % {s: striker.name, g: goalkeeper.name}
      end
    end

    def msg_goal(striker, goalkeeper, in_air: false)
      if in_air == true then
        ["Goal!! Great header by %{s}!",
         "Goal!! %{s} scores a fantastic goal!",
         "Goal!! Incredible strike by %{s}!",
        ].sample % {s: striker.name, g: goalkeeper.name}
      else
        ["Goal!! Great strike by %{s}!",
         "Goal!! %{s} scores a fantastic goal!",
         "Goal!! Incredible strike by %{s}!",
        ].sample % {s: striker.name, g: goalkeeper.name}
      end
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

    def msg_cross(kicker, target)
      ["%{k} crosses it in towards %{t}",
       "Clever cross from %{k}",
       "%{k} with a cross into the box"
      ].sample % {k: kicker.name, t: target.name}
    end

    def msg_corner_won()
      "It's a corner."
    end

    def msg_corner_take(kicker)
      ["%{p} takes the corner",
       "%{p} with the corner"
      ].sample % {p: kicker.name}
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

    def action_shoot(striker, in_air: false)
      side = @last_event.side
      shot_from = ball_pos
      goals_pos = pos_of_goals(1 - side)
      dist_to_goals = PitchPos.dist(goals_pos, ball_pos)
      # in attack position. try shot
      goalkeeper = get_goalkeeper(1 - side)

      raise "gk not on team" unless goalkeeper.team_id == @teams[1 - side].id
      raise "striker not on team" unless striker.team_id == @teams[side].id

      emit_event("ShotTry", side, ball_pos, msg_shoots(striker, goalkeeper, in_air: in_air), striker.id)

      # this is carefully tuned so simulate before fucking with it
      if RngHelper.dice(2, skill(side, striker, :shooting, ball_pos)) >
         RngHelper.dice(1+dist_to_goals, 8) then
        # on target
        if RngHelper.dice(4, skill(side, striker, :shooting, ball_pos)) >
           RngHelper.dice(1+dist_to_goals, skill(1-side, goalkeeper, :handling, goals_pos)) +
           RngHelper.dice(1+2*dist_to_goals, skill(1-side, goalkeeper, :speed, goals_pos)) then
           emit_event("Goal", side, goals_pos, msg_goal(striker, goalkeeper, in_air: in_air), striker.id)
          # beat keeper
          if side == 0
            @game.home_goals += 1
          else
            @game.away_goals += 1
          end
        else
          # keeper saved
          emit_event("ShotSaved", 1 - side, goals_pos, msg_shot_saved(striker, goalkeeper), goalkeeper.id)
          if RngHelper.dice(1, skill(1 - side, goalkeeper, :handling, goals_pos)) <
             RngHelper.dice(1, skill(1 - side, goalkeeper, :speed, goals_pos)) then
             emit_event("Corner", side, goals_pos, msg_corner_won(), nil)
          end
        end
      else
        # missed
        msg = msg_shot_miss(striker, goalkeeper)
        emit_event("ShotMiss", side, goals_pos, msg, striker.id)
        emit_event("GoalKick", 1-side, goals_pos, msg, goalkeeper.id)
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

      defenders.each {|p|
        defender = p.player
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

      defenders.each {|p|
        defender = p.player
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

    def anyone_grab_ball(pos)
      p = any_team_receiver(pos)
      emit_event("Boring", p.side, pos, "#{p.player.name} in possession", p.player.id)
    end

    def goal_kick(side)
      goalkeeper = get_goalkeeper(side)
      pos = PitchPos.new((0..4).to_a.sample, 3)
      emit_event("Boring", side, pos, "Goal kick by #{goalkeeper.name}", goalkeeper.id)
      anyone_grab_ball(pos)
    end
  end
end
