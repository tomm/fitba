class AddStatusToTransferBids < ActiveRecord::Migration
  def change
    execute "DELETE FROM transfer_bids"
    add_column :transfer_bids, :status, :string, null: false
  end
end
