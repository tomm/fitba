class AddPlayerToGameEvents < ActiveRecord::Migration
  def change
    add_reference :game_events, :player, index: true, foreign_key: true
  end
end
