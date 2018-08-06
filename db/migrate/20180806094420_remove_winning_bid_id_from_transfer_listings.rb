class RemoveWinningBidIdFromTransferListings < ActiveRecord::Migration
  def change
    remove_reference :transfer_listings, :winning_bid, index: true, foreign_key: true
  end
end
