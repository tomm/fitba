require "./app/name_gen.rb"
class AddForenameToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :forename, :string
    Player.all.each do |p|
      p.update(forename: NameGen.forename)
    end
    execute "ALTER TABLE players ALTER COLUMN forename SET NOT NULL"
    execute "ALTER TABLE players ALTER COLUMN name SET NOT NULL"
  end
end
