# typed: true
class CreateSessions < ActiveRecord::Migration[4.2]
  def change
    create_table :sessions do |t|
      t.string :hash
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
