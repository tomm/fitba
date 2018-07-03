class RemoveSeasonFromLeagues < ActiveRecord::Migration
  def change
    remove_column :leagues, :season, :integer
  end
end
