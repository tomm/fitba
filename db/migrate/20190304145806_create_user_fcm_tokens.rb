class CreateUserFcmTokens < ActiveRecord::Migration[5.2]
  def change
    create_table :user_fcm_tokens do |t|
      t.references :user, foreign_key: true, null: false
      t.string :token, null: false

      t.timestamps
    end
  end
end
