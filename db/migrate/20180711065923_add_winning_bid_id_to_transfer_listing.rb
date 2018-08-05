class AddWinningBidIdToTransferListing < ActiveRecord::Migration
  def change
    add_column :transfer_listings, :winning_bid_id, :integer
    add_foreign_key :transfer_listings, :transfer_bids, column: :winning_bid_id
  end
end
