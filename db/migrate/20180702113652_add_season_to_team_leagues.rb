class AddSeasonToTeamLeagues < ActiveRecord::Migration
  def change
    add_column :team_leagues, :season, :integer
  end
end
