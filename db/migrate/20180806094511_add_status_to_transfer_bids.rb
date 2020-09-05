# typed: true
class AddStatusToTransferBids < ActiveRecord::Migration[4.2]
  def change
    execute "DELETE FROM transfer_bids"
    add_column :transfer_bids, :status, :string, null: false
  end
end
