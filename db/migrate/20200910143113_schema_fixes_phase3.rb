# typed: true
class SchemaFixesPhase3 < ActiveRecord::Migration[5.2]
  def change
    ActiveRecord::Base.connection.execute(
      "
      alter table formation_pos alter column player_id set not null;
      alter table formation_pos alter column formation_id set not null;
      alter table formation_pos alter column position_num set not null;
      alter table formation_pos alter column position_x set not null;
      alter table formation_pos alter column position_y set not null;

      alter table transfer_listings alter column player_id set not null;
      alter table transfer_listings alter column min_price set not null;
      alter table transfer_listings alter column deadline set not null;
      alter table transfer_listings alter column status set not null;
      
      "
    )
  end
end
