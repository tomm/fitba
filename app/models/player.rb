# typed: strict
require 'json'
require './app/name_gen.rb'

class Player < ApplicationRecord
  extend T::Sig

  belongs_to :team, optional: true
  has_many :formation_pos, dependent: :delete_all
      
  ALL_SKILLS = T.let([:shooting, :passing, :tackling, :handling, :speed], T::Array[Symbol])

  sig {returns(T.untyped)}
  def to_api
    {
      id: self.id,
      name: self.name,
      age: self.age,
      forename: self.forename,
      shooting: self.shooting,
      passing: self.passing,
      tackling: self.tackling,
      handling: self.handling,
      speed: self.speed,
      injury: self.injury,
      form: self.form,
      wage: self.wage,
      suspension: self.suspension,
      season_stats: self.get_season_stats,
      positions: self.get_positions,
      is_transfer_listed: TransferListing.where(player_id: self.id, status: 'Active').where('deadline >= now()').count > 0
    }
  end

  sig {returns(T.untyped)}
  def get_season_stats
    season = SeasonHelper.current_season

    {
      goals: ActiveRecord::Base.connection.execute("
        select count(*) from game_events
        join games on games.id=game_events.game_id
        where game_events.kind='Goal'
          and games.season=#{season}
          and game_events.player_id=#{self.id.to_i}
      ").column_values(0).first,

      played: ActiveRecord::Base.connection.execute("
        select count(*) from games
        join formations
          on (games.home_formation_id = formations.id or games.away_formation_id=formations.id)
        join formation_pos on formation_pos.formation_id=formations.id
        where formation_pos.player_id=#{self.id.to_i}
          and formation_pos.position_num < 11
          and games.season=#{season}
      ").column_values(0).first
    }
  end

  AGE_PRICE_MULTIPLIER = T.let([
    # age 0-9 ;)
    0.0, 0.0, 0.0, 0.0, 0.0,  0.0, 0.0, 0.0, 0.0, 0.0,
    # age 10-19
    0.0, 0.0, 0.0, 0.0, 0.0,  0.0, 1.0, 1.5, 2.0, 2.0,
    # age 20-29
    2.0, 1.9, 1.8, 1.7, 1.6,  1.5, 1.4, 1.3, 1.2, 1.1,
    # age 30-39
    1.0, 0.9, 0.8, 0.7, 0.6,  0.5, 0.4, 0.3, 0.2, 0.1
  ], T::Array[Float])

  sig {returns(Integer)}
  def valuation
    age_mult = AGE_PRICE_MULTIPLIER[self.age] || 0.0
    return (self.skill * 200000 * age_mult).to_i
  end

  sig {returns(String)}
  def to_s
    "#{self.forename} #{self.name} of #{self.team}: Sh #{self.shooting}, Pa #{self.passing}, Ta #{self.tackling}, Ha #{self.handling}, Sp #{self.speed}"
  end

  sig {returns(T::Boolean)}
  def can_play?
    self.injury == 0 && self.suspension == 0
  end

  sig {returns(Integer)}
  def skill
    shooting + passing + tackling + handling + speed
  end

  sig {returns(T::Array[[Integer,Integer]])}
  def get_positions
    JSON.parse(positions)
  end

  sig {void}
  def happy_birthday
    self.age = self.age + 1
    # reduce skills on old players!
    (self.age - 30).times do
      which_skill = ALL_SKILLS.sample.to_s
      v = self.method(which_skill.to_sym).call()
      if v > 1 then
        self.method((which_skill + "=").to_sym).call(v-1)
      end
    end
    # wage changes for youth teamers
    self.wage = PlayerHelper.pick_daily_wage(self) if self.age <= 18

    self.save
  end

  sig {params(player_spawn_quality: Integer).returns(Player)}
  def self.random(player_spawn_quality)
    player_spawn_quality = player_spawn_quality > 0 ? player_spawn_quality : 0
    skill_range = (
      case player_spawn_quality
        # youth teamer
        when 0
          (1..3)
        # normal AI team qualities
        when 1
          (1..6)
        when 2
          (1..6)
        when 3
          (1..7)
        when 4
          (1..7)
        when 5
          (1..8)
        when 6
          (1..9)
        when 7
          (2..9)
        when 8
          (3..9)
        else
          (4..9)
      end
    ).to_a

    rand_skill = lambda { skill_range.sample }

    player = new(
      name: NameGen.surname,
      forename: NameGen.forename,
      age: (rand*12 + 18).round,
      shooting: rand_skill.call(),
      passing: rand_skill.call(),
      tackling: rand_skill.call(),
      handling: rand_skill.call(),
      speed: rand_skill.call(),
      form: RngHelper.dice(1,3) - 1,
      aggression: PlayerHelper.pick_aggression(),
      positions: "[]"
    )

    player.positions = JSON.generate(player.pick_positions(nil))
    player.wage = PlayerHelper.pick_daily_wage(player)
    
    player
  end

  sig {returns(String)}
  def pick_position
    # the kind of crack-smoking shit you code in a garbage-collected language
    pos = T.cast(
      (["A"]*shooting +
      ["AM"]*((shooting + passing)/2) +
      ["M"]*passing +
      ["DM"]*((passing + tackling)/2) +
      ["D"]*tackling +
      ["G"]*(handling/2)).sample, String
    )
    if pos != 'G' and pos != 'A'
      pos + T.cast(['L', 'R', 'C', 'C', 'C'].sample, String)
    else
      pos
    end
  end

  sig {params(force_position: T.any(NilClass, String)).returns(T::Array[[Integer,Integer]])}
  def pick_positions(force_position)
    if force_position then pos = force_position else pos = pick_position end
    case pos
      when 'A' then [[1,1],[2,1],[3,1]]

      when 'AML' then [[0,2],[0,1]]
      when 'AMR' then [[4,2],[4,1]]
      when 'AMC' then [[1,2],[2,2],[3,2]]

      when 'ML' then [[0,3],[0,2]]
      when 'MR' then [[4,3],[4,2]]
      when 'MC' then [[1,3],[2,3],[3,3]]

      when 'DML' then [[0,4],[0,3]]
      when 'DMR' then [[4,4],[4,3]]
      when 'DMC' then [[1,4],[2,4],[3,4]]

      when 'DL' then [[0,5],[0,4]]
      when 'DR' then [[4,5],[4,4]]
      when 'DC' then [[1,5],[2,5],[3,5]]

      when 'G' then [[2,6]]
      else raise "Unexpected value: " + pos
    end
  end
end
