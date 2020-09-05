# typed: true
class CreateTeams < ActiveRecord::Migration[4.2]
  def change
    create_table :teams do |t|
      t.string :name
      t.references :formation, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
