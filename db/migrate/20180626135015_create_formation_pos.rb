class CreateFormationPos < ActiveRecord::Migration[4.2]
  def change
    create_table :formation_pos do |t|
      t.references :formation, index: true, foreign_key: true
      t.references :player, index: true, foreign_key: true
      t.integer :position_num
      t.integer :position_x
      t.integer :position_y

      t.timestamps null: false
    end
  end
end
