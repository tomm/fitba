class AddFormToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :form, :integer, null: false, default: 0
    execute "UPDATE players SET form=FLOOR(RANDOM()*3)"
  end
end
