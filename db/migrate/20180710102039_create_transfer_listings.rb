class CreateTransferListings < ActiveRecord::Migration
  def change
    create_table :transfer_listings do |t|
      t.references :player, index: true, foreign_key: true
      t.integer :min_price
      t.date :deadline
      t.string :status

      t.timestamps null: false
    end
  end
end
