class AddPositionsToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :positions, :string
  end
end
