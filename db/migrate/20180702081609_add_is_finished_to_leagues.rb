class AddIsFinishedToLeagues < ActiveRecord::Migration
  def change
    add_column :leagues, :is_finished, :boolean
  end
end
