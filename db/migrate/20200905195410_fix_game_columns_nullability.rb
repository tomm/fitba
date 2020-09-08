class FixGameColumnsNullability < ActiveRecord::Migration[5.2]
  def change
    ActiveRecord::Base.connection.execute(
      "alter table games alter column home_team_id set not null"
    )
    ActiveRecord::Base.connection.execute(
      "alter table games alter column away_team_id set not null"
    )
    ActiveRecord::Base.connection.execute(
      "alter table games alter column home_goals set not null"
    )
    ActiveRecord::Base.connection.execute(
      "alter table games alter column away_goals set not null"
    )
    ActiveRecord::Base.connection.execute(
      "alter table games alter column league_id set not null"
    )
    ActiveRecord::Base.connection.execute(
      "alter table game_events alter column time set not null"
    )
  end
end
