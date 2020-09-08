# typed: true
class AddSeasonToTeamLeagues < ActiveRecord::Migration[4.2]
  def change
    add_column :team_leagues, :season, :integer
  end
end
