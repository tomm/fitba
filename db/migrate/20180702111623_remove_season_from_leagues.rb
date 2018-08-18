class RemoveSeasonFromLeagues < ActiveRecord::Migration[4.2]
  def change
    remove_column :leagues, :season, :integer
  end
end
