class GameEvent < ActiveRecord::Base
  belongs_to :game

  # type: KickOff | Goal | Boring | Shot
  # side: 0: home, 1: away
end
