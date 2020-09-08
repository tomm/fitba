# typed: true
class AddRankColumnToLeague < ActiveRecord::Migration[4.2]
  def change
    add_column :leagues, :rank, :integer
  end
end
