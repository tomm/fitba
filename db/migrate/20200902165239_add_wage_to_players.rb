# typed: true
class AddWageToPlayers < ActiveRecord::Migration[5.2]
  def change
    add_column :players, :wage, :integer, null: false, default: 0

    Player.all.each do |p|
      p.update!(wage: PlayerHelper.pick_daily_wage(p))
    end
  end
end
