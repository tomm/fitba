# typed: true
class AddSeasonToGames < ActiveRecord::Migration[4.2]
  def change
    add_column :games, :season, :integer
  end
end
