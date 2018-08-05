class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.references :league, index: true, foreign_key: true
      t.integer :home_team_id, index: true, references: :teams, foreign_key: {to_table: :teams}
      t.integer :away_team_id, index: true, references: :teams, foreign_key: {to_table: :teams}
      t.string :status
      t.datetime :start
      t.integer :home_goals
      t.integer :away_goals

      t.timestamps null: false
    end
  end
end
