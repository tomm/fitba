class CreateTeamLeagues < ActiveRecord::Migration
  def change
    create_table :team_leagues do |t|
      t.references :team, index: true, foreign_key: true
      t.references :league, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
