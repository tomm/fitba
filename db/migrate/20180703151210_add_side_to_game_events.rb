class AddSideToGameEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :game_events, :side, :integer
  end
end
