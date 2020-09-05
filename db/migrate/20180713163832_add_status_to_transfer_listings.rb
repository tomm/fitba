# typed: true
class AddStatusToTransferListings < ActiveRecord::Migration[4.2]
  def change
    add_column :transfer_listings, :status, :string
  end
end
