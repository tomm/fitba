# typed: true
class AddStageToGames < ActiveRecord::Migration[5.2]
  def change
    add_column :games, :stage, :integer
  end
end
