class AddIdentifierColumnToSession < ActiveRecord::Migration[4.2]
  def change
    add_column :sessions, :identifier, :string
  end
end
