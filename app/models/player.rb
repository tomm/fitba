class Player < ActiveRecord::Base
  belongs_to :team
  has_many :formation_pos

  def to_api
    {
      id: id,
      name: name,
      shooting: shooting,
      passing: passing,
      tackling: tackling,
      handling: handling,
      speed: speed
    }
  end

  def skill
    shooting + passing + tackling + handling + speed
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
    if pos != 'G'
      pos + ['L', 'R', 'C', 'C'].sample
    else
      pos
    end
  end
end
