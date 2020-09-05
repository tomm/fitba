# typed: true
class AddFormToPlayers < ActiveRecord::Migration[4.2]
  def change
    add_column :players, :form, :integer, null: false, default: 0
    execute "UPDATE players SET form=FLOOR(RANDOM()*3)"
  end
end
