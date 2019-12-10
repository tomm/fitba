class CreateUserInvites < ActiveRecord::Migration[5.2]
  def change
    create_table :user_invites do |t|
      t.string :code, null: false
      t.string :welcome_name

      t.timestamps
    end
  end
end
