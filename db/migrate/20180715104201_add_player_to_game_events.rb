# typed: true
class AddPlayerToGameEvents < ActiveRecord::Migration[4.2]
  def change
    add_reference :game_events, :player, index: true, foreign_key: true
  end
end
