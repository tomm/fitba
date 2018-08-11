class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.references :team, index: true, foreign_key: true, null: false
      t.string :from, null: false
      t.string :subject, null: false
      t.text :body, null: false
      t.datetime :date, null: false

      t.timestamps null: false
    end
  end
end
