class AddPlayerSpawnQualityToTeams < ActiveRecord::Migration
  def change
    add_column :teams, :player_spawn_quality, :integer, null: false, default: 5
  end
end
