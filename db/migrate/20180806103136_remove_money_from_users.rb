class RemoveMoneyFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :money, :integer
  end
end
