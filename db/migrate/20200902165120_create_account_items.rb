# typed: true
class CreateAccountItems < ActiveRecord::Migration[5.2]
  def change
    create_table :account_items do |t|
      t.string :description
      t.integer :amount
      t.integer :season
      t.references :team

      t.timestamps
    end
  end
end
