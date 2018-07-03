class AddSpeedToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :speed, :integer
  end
end
