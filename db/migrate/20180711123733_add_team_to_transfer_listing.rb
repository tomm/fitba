class AddTeamToTransferListing < ActiveRecord::Migration[4.2]
  def change
    add_reference :transfer_listings, :team, index: true, foreign_key: true
  end
end
