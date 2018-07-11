class AddWinningBidIdToTransferListing < ActiveRecord::Migration
  def change
    add_reference :transfer_listings, :winning_bid, index: true, foreign_key: true
  end
end
