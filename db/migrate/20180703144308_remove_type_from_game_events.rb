class RemoveTypeFromGameEvents < ActiveRecord::Migration
  def change
    remove_column :game_events, :type, :string
  end
end
