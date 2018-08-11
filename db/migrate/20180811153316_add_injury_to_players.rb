class AddInjuryToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :injury, :integer, null: false, default: 0
  end
end
