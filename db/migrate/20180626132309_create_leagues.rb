# typed: true
class CreateLeagues < ActiveRecord::Migration[4.2]
  def change
    create_table :leagues do |t|
      t.string :name
      t.boolean :isFinished

      t.timestamps null: false
    end
  end
end
