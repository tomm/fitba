class TransferListing < ActiveRecord::Base
  belongs_to :player
  belongs_to :winning_bid, :class_name => 'TransferBid'
end
