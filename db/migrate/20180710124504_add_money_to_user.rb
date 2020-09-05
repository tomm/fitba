# typed: true
class AddMoneyToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :money, :integer
  end
end
