class AddTeamToTransferListing < ActiveRecord::Migration
  def change
    add_reference :transfer_listings, :team, index: true, foreign_key: true
  end
end
