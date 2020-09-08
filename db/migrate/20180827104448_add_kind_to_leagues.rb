# typed: true
class AddKindToLeagues < ActiveRecord::Migration[5.2]
  def change
    add_column :leagues, :kind, :string, null: false, default: "League"
  end
end
