class AddRankColumnToLeague < ActiveRecord::Migration
  def change
    add_column :leagues, :rank, :integer
  end
end
