class AddPlayerSpawnQualityToTeams < ActiveRecord::Migration[4.2]
  def change
    add_column :teams, :player_spawn_quality, :integer, null: false, default: 5
  end
end
