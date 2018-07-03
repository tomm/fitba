class AddSideToGameEvents < ActiveRecord::Migration
  def change
    add_column :game_events, :side, :integer
  end
end
