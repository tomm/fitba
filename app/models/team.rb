# typed: strict
class Team < ApplicationRecord
  extend T::Sig

  belongs_to :formation
  has_many :team_leagues
  has_many :players
  has_many :messages

  scope :in_league_season, ->(league_id, season) { 
    joins(:team_leagues).where({
      team_leagues: {
        league_id: league_id,
        season: season
      }
    })
  }

  # Used when players are sold. Removes them from the team formation,
  # but not from formations linked from games (because that's active or historic data)
  sig {params(player: Player).void}
  def remove_player_from_squad(player)
    FormationPo.where(formation_id: self.formation_id, player_id: player.id).delete_all
  end

  sig {returns(String)}
  def to_s
    self.name
  end

  sig {params(from: String, subject: String, body: String, date: Time).void}
  def send_message(from, subject, body, date)
    Message.send_message(self, from, subject, body, date)
  end

  sig {returns(T::Boolean)}
  def is_actively_managed_by_human?
    !!Session.where(
      user_id: User.where(team_id: self.id).first&.id
    ).order(:updated_at).reverse_order.first&.updated_at&.method(:>)&.call(Time.now - 30.day)
  end

  sig {returns(FormationPo::ActiveRecord_Relation)}
  def player_positions
    f = self.formation
    raise "Bug" if f.nil?

    f.positions_ordered
  end

  sig {returns(T.untyped)}
  def squad
    positions = player_positions.all
    players = Player.where(team_id: self.id).all
    squad = []

    # add starting players in order
    positions.each do |pos|
      player = players.detect {|p| p.id == pos.player_id}
      squad << player unless player == nil
    end

    # then add non-starters
    squad |= players

    {
      # make sure there are 11 positions!
      formation: positions = ((0..10).map do |i|
        if i == 0 then
          # GK mandatory!
          [2, 6]
        elsif positions[i] == nil then
          AiManagerHelper::FORMATION_442[i]
        else
          [positions[i].position_x, positions[i].position_y]
        end
      end),
      players: squad.map {|p| p.to_api }
    }
  end

  sig {params(positions: T::Array[[Integer, [Integer, Integer]]]).void}
  def update_player_positions(positions) # [[playerId, [positionX, positionY]]]
    # positions are in order, ie [0] is goal keeper, [10] is centre forward
    #players = Player.find_by(team_id: self.id)
    # move existing positions away
    all_player_id = Player.where(team_id: self.id).pluck(:id)

    # make sure they are our players
    positions.select! {|p| all_player_id.include?(p[0]) }

    # add missing playerIds at end of positions
    all_player_id.each do |player_id|
      if not positions.any? {|p| p[0] == player_id} then
        positions << [player_id, [0,0]]
      end
    end

    # nuke any formation positions to players not on this team...
    FormationPo.where(formation_id: self.formation_id).where.not(player_id: all_player_id).delete_all

    positions.each_with_index do |p,i|
      player_id = p[0]
      position_xy = p[1]
      if i == 0 then
        # GK mandatory
        position_xy = [2,6]
      end
      if position_xy == nil then position_xy = [0,0] end
      # ^^ haskell version handles this differently, saving a combined "Maybe (Int,Int) field to DB
      # first check it's our player
      formation_po = FormationPo.find_by(player_id: player_id, formation_id: self.formation_id)
      if formation_po == nil
        FormationPo.create(formation_id: self.formation_id,
                           player_id: player_id,
                           position_num: i,
                           position_x: position_xy[0], position_y: position_xy[1])
      else
        formation_po.update(position_num: i, position_x: position_xy[0], position_y: position_xy[1])
      end
    end
  end
end
