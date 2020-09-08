# typed: true
class RemoveHashFromSession < ActiveRecord::Migration[4.2]
  def change
    remove_column :sessions, :hash, :string
  end
end
