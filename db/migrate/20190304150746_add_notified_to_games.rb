# typed: true
class AddNotifiedToGames < ActiveRecord::Migration[5.2]
  def change
    add_column :games, :notified, :boolean, null: false, default: false
  end
end
