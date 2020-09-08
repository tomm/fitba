# typed: strict
class TransferListing < ApplicationRecord
  belongs_to :player
  belongs_to :team
  has_many :transfer_bids, dependent: :destroy
  # status = Active | Sold | Unsold
end
