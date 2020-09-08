# typed: true
class AddSubsToGames < ActiveRecord::Migration[5.2]
  def change
    add_column :games, :home_subs, :integer, null: false, default: 0
    add_column :games, :away_subs, :integer, null: false, default: 0
  end
end
