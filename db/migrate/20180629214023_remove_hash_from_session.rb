class RemoveHashFromSession < ActiveRecord::Migration
  def change
    remove_column :sessions, :hash, :string
  end
end
