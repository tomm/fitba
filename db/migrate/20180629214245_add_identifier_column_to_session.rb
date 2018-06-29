class AddIdentifierColumnToSession < ActiveRecord::Migration
  def change
    add_column :sessions, :identifier, :string
  end
end
