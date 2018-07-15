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
BASE_SKILL = 5

MATCH_LENGTH_SECONDS = 270

class PitchPos
  attr_reader :x, :y
  def initialize(x, y)
    @x = x
    @y = y
  end

  # Flip home coords to away coords
  def flip
    PitchPos.new(4 - @x, 6 - @y)
  end

  def to_s
    "#{@x},#{@y}"
  end
end

class TeamPos
  def initialize(team)

    positions = team.formation.formation_pos
    
    @pos_to_player_id = ALL_POS.map do |p|
      pitch_pos = PitchPos.new(p[0], p[1])
      pos = positions.find {|q| q.position_x == pitch_pos.x and q.position_y == pitch_pos.y }
      [pitch_pos.to_s, pos == nil ? nil : pos.player_id]
    end.to_h
  end

  def whos_at(pitch_pos)
    @pos_to_player_id[pitch_pos.to_s]
  end

  def whos_at_exclude_gk(pitch_pos)
    if pitch_pos.x == 2 and pitch_pos.y == 6
      nil
    else
      @pos_to_player_id[pitch_pos.to_s]
    end
  end

  # exclude GK
  def whos_adjacent(pitch_pos)
    adjacent = []
    (-1..1).each do |xinc|
      (-1..1).each do |yinc|
        if not (xinc == 0 and yinc == 0)
          if at = whos_at_exclude_gk(PitchPos.new(pitch_pos.x + xinc, pitch_pos.y + yinc))
            adjacent << at
          end
        end
      end
    end
    adjacent
  end
end

class GameSimulator
  def initialize(game)
    @game = game
    @teams = [game.home_team, game.away_team]
    @team_pos = [
      TeamPos.new(game.home_team),
      TeamPos.new(game.away_team)
    ]
    @player_by_id = ((game.home_team.formation.formation_pos + game.away_team.formation.formation_pos).map do |f|
      [f.player_id, f.player]
    end).to_h
    @last_event = GameEvent.where(game_id: game.id).order(:time).reverse_order.first
  end

  def dice(n,s)
    x=0
    (1..n).each do |_|
      x += 1 + (rand*s).to_i; 
    end
    x
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
        side: dice(1,2) - 1,
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

  def simulate_tick()
    # kick off
    if @last_event == nil || @last_event.kind == 'Goal'
      kick_off()
    else
      pos = PitchPos.new(@last_event.ball_pos_x, @last_event.ball_pos_y)

      home_skill = get_skill_near(pos, 0)
      away_skill = get_skill_near(pos, 1)

      diff = dice(1, home_skill + BASE_SKILL) - dice(1, away_skill + BASE_SKILL)
      if diff > 0
        # home team advances
        advance(0)
      elsif diff < 0
        advance(1)
      else
        no_advance()
      end
    end
  end

  def no_advance
    @last_event = GameEvent.create(
      game_id: @game.id,
      kind: 'Boring',
      side: @last_event.side,
      time: @last_event.time + 1,
      message: nil,
      ball_pos_x: @last_event.ball_pos_x,
      ball_pos_y: @last_event.ball_pos_y
    )
  end

  def strike(team, striker)
    # in attack position. try shot
    goalkeeper = get_goalkeeper(1 - team)

    raise "gk not on team" unless goalkeeper.team_id == @teams[1 - team].id
    raise "striker not on team" unless striker.team_id == @teams[team].id

    @last_event = GameEvent.create(
      game_id: @game.id,
      kind: 'Shot',
      side: team,
      time: @last_event.time + 1,
      message: "#{striker.name} shoots!",
      ball_pos_x: @last_event.ball_pos_x,
      ball_pos_y: @last_event.ball_pos_y,
      player_id: striker.id
    )

    if dice(1, striker.skill + BASE_SKILL) > dice(2, goalkeeper.skill + BASE_SKILL) 
      @last_event = GameEvent.create(
        game_id: @game.id,
        kind: 'Goal',
        side: team,
        time: @last_event.time + 1,
        message: "Goal!! Great strike by #{striker.name}",
        ball_pos_x: @last_event.ball_pos_x,
        ball_pos_y: @last_event.ball_pos_y,
        player_id: striker.id
      )
      if team == 0
        @game.home_goals += 1
      else
        @game.away_goals += 1
      end
    else
      @last_event = GameEvent.create(
        game_id: @game.id,
        kind: 'Shot',
        side: team,
        time: @last_event.time + 1,
        message: ["Great save by #{goalkeeper.name}!", "It goes wide!"].sample,
        ball_pos_x: @last_event.ball_pos_x,
        ball_pos_y: @last_event.ball_pos_y,
        player_id: striker.id
      )
    end
  end

  def advance(team) # team 0 = home, 1 = away
      pos = PitchPos.new(@last_event.ball_pos_x, @last_event.ball_pos_y)
      team_rel_pos = if team == 0 then pos else pos.flip end

      if team_rel_pos.y == 1
        if striker = get_random_near(pos, team)
          strike(team, striker)
        else
          # nobody around to take a shot. crap formation ;)
          no_advance()
        end
      else
        # find new position
        pos = PitchPos.new((0..4).to_a.sample, team_rel_pos.y - 1)
        if team == 1 then pos = pos.flip end
        @last_event = GameEvent.create(
          game_id: @game.id,
          kind: 'Boring',
          side: team,
          time: @last_event.time + 1,
          message: nil,
          ball_pos_x: pos.x,
          ball_pos_y: pos.y
        )
      end
  end

  def get_goalkeeper(team)
    @player_by_id[@team_pos[team].whos_at(PitchPos.new(GK[0], GK[1]))]
  end

  # Player | nil
  def get_random_near(pos, team) # team 0 = home, 1 = away
    if team == 1 then pos = pos.flip end
    at_pos = @team_pos[team].whos_at(pos)
    near = @team_pos[team].whos_adjacent(pos)
    if at_pos != nil then
      # greater chance of player of this position being chosen
      near << at_pos
      near << at_pos
    end
    @player_by_id[near.sample]
  end

  # add up skills of players at or adjacent to 'pos'. players at pos receive double points
  def get_skill_near(pos, team) # team 0 = home, 1 = away
    if team == 1 then pos = pos.flip end
    at_pos = @team_pos[team].whos_at(pos)
    near_pos = @team_pos[team].whos_adjacent(pos)
    skill = at_pos == nil ? 0 : 2 * @player_by_id[at_pos].skill
    near_pos.each do |pid|
      skill += @player_by_id[pid].skill
    end
    skill
  end

  def kick_off
    @last_event = GameEvent.create(
      game_id: @game.id,
      kind: 'KickOff',
      side: dice(1,2) - 1, # XXX more logic here
      time: @last_event == nil ? @game.start : @last_event.time + 1,
      message: 'Kick off!',
      ball_pos_x: 2,
      ball_pos_y: 3
    )
  end
end
