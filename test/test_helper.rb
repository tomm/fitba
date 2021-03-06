# typed: false
ENV['RAILS_ENV'] ||= 'test'

require 'simplecov'
SimpleCov.start 'rails' do
  add_filter "/test/"
end

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
  def login
    user = users(:user_tom)
    s = Session.create(user_id: user.id, identifier: 'blah')
    request.cookies[:session] = s.identifier
    user
  end
end
