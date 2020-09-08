class SchemaTighteningScrewsPart2 < ActiveRecord::Migration[5.2]
  def change
    ActiveRecord::Base.connection.execute(
      "alter table teams alter column name set not null"
    )
  end
end
