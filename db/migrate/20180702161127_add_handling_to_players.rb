class AddHandlingToPlayers < ActiveRecord::Migration[4.2]
  def change
    add_column :players, :handling, :integer
  end
end
