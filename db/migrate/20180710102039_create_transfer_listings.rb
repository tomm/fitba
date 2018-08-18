class CreateTransferListings < ActiveRecord::Migration[4.2]
  def change
    create_table :transfer_listings do |t|
      t.references :player, index: true, foreign_key: true
      t.integer :min_price
      t.datetime :deadline
      t.string :status

      t.timestamps null: false
    end
  end
end
