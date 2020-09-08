# typed: true
class CreateGameEvents < ActiveRecord::Migration[4.2]
  def change
    create_table :game_events do |t|
      t.references :game, index: true, foreign_key: true
      t.string :type
      t.datetime :time
      t.text :message
      t.integer :ball_pos_x
      t.integer :ball_pos_y

      t.timestamps null: false
    end
  end
end
