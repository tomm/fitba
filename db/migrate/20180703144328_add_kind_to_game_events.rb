class AddKindToGameEvents < ActiveRecord::Migration
  def change
    add_column :game_events, :kind, :string
  end
end
