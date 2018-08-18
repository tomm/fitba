class RemoveIsFinishedFromLeagues < ActiveRecord::Migration[4.2]
  def change
    remove_column :leagues, :isFinished, :boolean
  end
end
