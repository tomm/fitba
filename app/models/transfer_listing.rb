class TransferListing < ActiveRecord::Base
  belongs_to :player
  has_many :transfer_bids, dependent: :destroy
  # status = Active | Sold | Unsold
end
