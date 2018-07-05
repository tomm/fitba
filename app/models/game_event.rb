class GameEvent < ActiveRecord::Base
  belongs_to :game

  # type: KickOff | Goal | Boring | Shot | EndOfGame XXX TODO use this
  # side: 0: home, 1: away
end
