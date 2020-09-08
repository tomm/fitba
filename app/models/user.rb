# typed: strict
class User < ApplicationRecord
  belongs_to :team
  has_many :sessions
end
