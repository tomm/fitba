class RemoveTypeFromGameEvents < ActiveRecord::Migration[4.2]
  def change
    remove_column :game_events, :type, :string
  end
end
