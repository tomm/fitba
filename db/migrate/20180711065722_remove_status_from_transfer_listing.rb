class RemoveStatusFromTransferListing < ActiveRecord::Migration[4.2]
  def change
    remove_column :transfer_listings, :status, :string
  end
end
