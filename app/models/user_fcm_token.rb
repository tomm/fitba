class UserFcmToken < ApplicationRecord
  belongs_to :user

  scope :for_team_id, ->(team_id) {
    joins(:user).where({users: {team_id: team_id}})
  }
end
