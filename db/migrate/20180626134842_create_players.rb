class CreatePlayers < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.references :team, index: true, foreign_key: true
      t.string :name
      t.integer :shooting
      t.integer :passing
      t.integer :tackling
      t.integer :goalkeeping

      t.timestamps null: false
    end
  end
end
