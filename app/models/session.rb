# typed: strict
class Session < ApplicationRecord
  belongs_to :user
end
