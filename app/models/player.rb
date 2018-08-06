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
