class AddPositionsToPlayers < ActiveRecord::Migration[4.2]
  def change
    add_column :players, :positions, :string
  end
end
