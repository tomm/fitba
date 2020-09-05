# typed: true
class AddSeasonToLeagues < ActiveRecord::Migration[4.2]
  def change
    add_column :leagues, :season, :integer
  end
end
