# typed: true
class AddPenaltiesToGames < ActiveRecord::Migration[5.2]
  def change
    add_column :games, :home_penalties, :integer, null: false, default: 0
    add_column :games, :away_penalties, :integer, null: false, default: 0
  end
end
