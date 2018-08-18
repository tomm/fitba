class AddTransferListingIdToTransferBid < ActiveRecord::Migration[4.2]
  def change
    add_reference :transfer_bids, :transfer_listing, index: true, foreign_key: true
  end
end
