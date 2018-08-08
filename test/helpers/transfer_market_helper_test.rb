require 'test_helper'
require 'date'

class TransferMarketHelperTest < ActiveSupport::TestCase
  test "repopulate_transfer_market" do
    num_listings = TransferListing.count
    TransferMarketHelper.spawn_transfer_listing
    assert_equal num_listings+1, TransferListing.count
  end
end
