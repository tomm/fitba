# typed: true
class CreateUniqueFcmUserIdToken < ActiveRecord::Migration[5.2]
  def change
    add_index :user_fcm_tokens, [:user_id, :token], unique: true
  end
end
