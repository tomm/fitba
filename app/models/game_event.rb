# typed: strict
class GameEvent < ApplicationRecord
  belongs_to :game

  # type: KickOff | Injury | Sub | Goal | GoalKick | Boring | ShotTry | ShotMiss | ShotSaved | Corner | EndOfGame XXX TODO use this
  # side: 0: home, 1: away
end
