# typed: true
class AddAggressionAndSuspensionToPlayers < ActiveRecord::Migration[5.2]
  def change
    add_column :players, :aggression, :integer, null: false, default: 1
    add_column :players, :suspension, :integer, null: false, default: 0

    Player.all.each do |p|
      p.update!(aggression: PlayerHelper.pick_aggression)
    end
  end
end
