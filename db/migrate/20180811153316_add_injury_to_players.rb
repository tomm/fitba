class AddInjuryToPlayers < ActiveRecord::Migration[4.2]
  def change
    add_column :players, :injury, :integer, null: false, default: 0
  end
end
