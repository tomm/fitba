class RemoveGoalkeepingFromPlayers < ActiveRecord::Migration[4.2]
  def change
    remove_column :players, :goalkeeping, :integer
  end
end
