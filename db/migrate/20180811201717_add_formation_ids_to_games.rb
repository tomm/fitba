# typed: true
class AddFormationIdsToGames < ActiveRecord::Migration[4.2]
  def change
    add_column :games, :home_formation_id, :integer
    add_column :games, :away_formation_id, :integer
    add_foreign_key :games, :formations, column: :home_formation_id
    add_foreign_key :games, :formations, column: :away_formation_id
  end
end
