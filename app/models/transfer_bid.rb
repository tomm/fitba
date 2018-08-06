class TransferBid < ActiveRecord::Base
  belongs_to :team
  belongs_to :transfer_listing
  # data Status = Pending | Won | OutBid | TeamRejected | PlayerRejected | InsufficientMoney
end
