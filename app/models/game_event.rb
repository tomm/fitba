class GameEvent < ActiveRecord::Base
  belongs_to :game

  # type: KickOff | Goal | Boring | ShotTry | ShotMiss | ShotSaved | EndOfGame XXX TODO use this
  # side: 0: home, 1: away
end
