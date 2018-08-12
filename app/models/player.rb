require 'json'
require './app/name_gen.rb'

class Player < ActiveRecord::Base
  belongs_to :team
  has_many :formation_pos, dependent: :delete_all
      
  ALL_SKILLS = [:shooting, :passing, :tackling, :handling, :speed]

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
      positions: self.get_positions
    }
  end

  def can_play?
    self.injury == 0
  end

  def skill
    shooting + passing + tackling + handling + speed
  end

  def get_positions
    JSON.parse(positions)
  end

  def happy_birthday
    self.age = self.age + 1
    # reduce skills on old players!
    (self.age - 30).times do
      which_skill = ALL_SKILLS.sample.to_s
      v = self.method(which_skill).call()
      if v > 1 then
        self.method(which_skill + "=").call(v-1)
      end
    end
    self.save
  end

  def self.random(player_spawn_quality)
    player_spawn_quality = player_spawn_quality >= 1 ? player_spawn_quality : 1
    skill_range = (
      case player_spawn_quality
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
      positions: "[]"
    )

    player.positions = JSON.generate(player.pick_positions(nil))
    
    player
  end

  def pick_position
    # the kind of crack-smoking shit you code in a garbage-collected language
    pos =
      (["A"]*shooting +
      ["AM"]*((shooting + passing)/2) +
      ["M"]*passing +
      ["DM"]*((passing + tackling)/2) +
      ["D"]*tackling +
      ["G"]*(handling/2)).sample
    if pos != 'G' and pos != 'A'
      pos + ['L', 'R', 'C', 'C', 'C'].sample
    else
      pos
    end
  end

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
