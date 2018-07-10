class AddTransferListingIdToTransferBid < ActiveRecord::Migration
  def change
    add_reference :transfer_bids, :transfer_listing, index: true, foreign_key: true
  end
end
