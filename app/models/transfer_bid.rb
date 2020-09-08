# typed: strict
class TransferBid < ApplicationRecord
  belongs_to :team
  belongs_to :transfer_listing
  # data Status = Pending | Won | OutBid | TeamRejected | PlayerRejected | InsufficientMoney
end
