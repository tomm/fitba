class RemoveIsFinishedFromLeagues < ActiveRecord::Migration
  def change
    remove_column :leagues, :isFinished, :boolean
  end
end
