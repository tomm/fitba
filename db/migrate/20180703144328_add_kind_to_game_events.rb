class AddKindToGameEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :game_events, :kind, :string
  end
end
