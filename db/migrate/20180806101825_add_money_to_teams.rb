class AddMoneyToTeams < ActiveRecord::Migration
  def change
    add_column :teams, :money, :integer, null: false, default: 0
    execute "UPDATE teams SET money=COALESCE((SELECT SUM(money) FROM users WHERE users.team_id = teams.id),0)"
  end
end