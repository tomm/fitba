# typed: true
class CreateAttendances < ActiveRecord::Migration[5.2]
  def change
    create_table :attendances do |t|
      t.references :game, foreign_key: true, null: false
      t.references :user, foreign_key: true, null: false

      t.timestamps
    end
    add_index :attendances, [:game_id, :user_id], unique: true
  end
end
