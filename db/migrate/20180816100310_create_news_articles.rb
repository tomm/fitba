# typed: true
class CreateNewsArticles < ActiveRecord::Migration[5.2]
  def change
    create_table :news_articles do |t|
      t.string :title, null: false
      t.string :body, null: false
      t.datetime :date, null: false

      t.timestamps
    end
  end
end
