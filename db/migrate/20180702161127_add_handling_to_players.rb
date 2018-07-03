class AddHandlingToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :handling, :integer
  end
end
