class RemoveStatusFromTransferListing < ActiveRecord::Migration
  def change
    remove_column :transfer_listings, :status, :string
  end
end
