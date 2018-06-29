class User < ActiveRecord::Base
  belongs_to :team
  has_many :sessions
end
