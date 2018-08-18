class AddSpeedToPlayers < ActiveRecord::Migration[4.2]
  def change
    add_column :players, :speed, :integer
  end
end
