# typed: true
class RemoveMoneyFromUsers < ActiveRecord::Migration[4.2]
  def change
    remove_column :users, :money, :integer
  end
end
