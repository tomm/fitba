class AddKindToLeagues < ActiveRecord::Migration[5.2]
  def change
    add_column :leagues, :kind, :string, null: false
  end
end
