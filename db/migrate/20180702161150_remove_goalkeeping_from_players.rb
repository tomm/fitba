class RemoveGoalkeepingFromPlayers < ActiveRecord::Migration
  def change
    remove_column :players, :goalkeeping, :integer
  end
end
