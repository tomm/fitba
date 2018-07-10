class CreateTransferBids < ActiveRecord::Migration
  def change
    create_table :transfer_bids do |t|
      t.references :team, index: true, foreign_key: true
      t.integer :amount

      t.timestamps null: false
    end
  end
end
