class CreateFormations < ActiveRecord::Migration[4.2]
  def change
    create_table :formations do |t|

      t.timestamps null: false
    end
  end
end
