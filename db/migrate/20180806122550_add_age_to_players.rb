class AddAgeToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :age, :integer
    execute "UPDATE players SET age=18+FLOOR(RANDOM()*12)"
    execute "ALTER TABLE players ALTER COLUMN age SET NOT NULL"
    execute "ALTER TABLE players ALTER COLUMN shooting SET NOT NULL"
    execute "ALTER TABLE players ALTER COLUMN passing SET NOT NULL"
    execute "ALTER TABLE players ALTER COLUMN tackling SET NOT NULL"
    execute "ALTER TABLE players ALTER COLUMN handling SET NOT NULL"
    execute "ALTER TABLE players ALTER COLUMN speed SET NOT NULL"
    execute "ALTER TABLE players ALTER COLUMN positions SET NOT NULL"
  end
end
