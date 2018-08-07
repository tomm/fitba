require 'json'

class Player < ActiveRecord::Base
  belongs_to :team
  has_many :formation_pos

  def to_api
    {
      id: id,
      name: name,
      age: age,
      forename: forename,
      shooting: shooting,
      passing: passing,
      tackling: tackling,
      handling: handling,
      speed: speed,
      positions: get_positions
    }
  end

  def skill
    shooting + passing + tackling + handling + speed
  end

  def get_positions
    JSON.parse(positions)
  end

  def self.random(team_id, player_spawn_skill)
    # player skill as '4+2d6' kinda thing
    m = player_spawn_skill.match(/(\d+)\+(\d+)d(\d+)/)
    rand_skill = lambda {
      skill = m[1].to_i + RngHelper.dice(m[2].to_i, m[3].to_i)
      skill >= 1 ? (skill <= 9 ? skill : 9) : 1
    }
    #puts "Creating player using #{m[1]} + #{m[2]}d#{m[3]}"

    player = new(
      team_id: team_id,
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
