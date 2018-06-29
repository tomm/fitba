class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.references :league, index: true, foreign_key: true
      t.references :home_team, index: true, foreign_key: true
      t.references :away_team, index: true, foreign_key: true
      t.string :status
      t.datetime :start
      t.integer :home_goals
      t.integer :away_goals

      t.timestamps null: false
    end
  end
end
