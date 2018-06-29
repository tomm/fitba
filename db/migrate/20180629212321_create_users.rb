class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.references :team, index: true, foreign_key: true
      t.string :secret

      t.timestamps null: false
    end
  end
end
