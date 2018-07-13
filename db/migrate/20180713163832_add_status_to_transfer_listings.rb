class AddStatusToTransferListings < ActiveRecord::Migration
  def change
    add_column :transfer_listings, :status, :string
  end
end
