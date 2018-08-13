TRANSFER_LISTING_DURATION = 60*60*23

module TransferMarketHelper
  def self.is_listed?(player_id)
    TransferListing.where(player_id: player_id, status: "Active").count > 0
  end

  def self.list_player(player)
    if not is_listed?(player.id) then
      price_jiggle = 1.0 + (rand * 0.1)
      TransferListing.create(team_id: player.team_id, status: 'Active', player: player,
                             min_price: player.skill * 200000 * price_jiggle,
                             deadline: Time.now + TRANSFER_LISTING_DURATION)
    end
  end

  def self.player_iterested_in_transfer(team, player)
    # don't let a team buy a player way out of their league
    # starting 11
    players = team.player_positions.limit(11).all.map(&:player).sort_by!(&:skill)
    num_players = players.length
    median_skill = players[num_players / 2].skill
    can_do = player.skill <= median_skill * 1.25
    puts "Attempt to buy player of skill #{player.skill} by team median skill #{median_skill}. Can do? #{can_do}"
    can_do
  end

  def self.spawn_transfer_listing()
    player = Player.random(RngHelper.dice(1,9))
    list_player(player)
    puts "Created new transfer market listing: #{player.name}"
  end

  def self.decide_transfer_market_bids()

    # resolve expired transfer listings
    expired = TransferListing.where("deadline < ?", Time.now).where(status: 'Active').all
    expired.each do |t|
      player = Player.find(t.player_id)
      bids = TransferBid.where(transfer_listing_id: t.id).order(:amount).reverse_order.all.to_a
      seller_team = Team.where(id: player.team_id).first
      sold = false

      while bids.length > 0 do
        bid = bids.shift
        buyer_team = Team.find(bid.team_id)
        
        if sold == true then
          # already sold
          bid.update(status: "OutBid")
          buyer_team.send_message("The Chairman", "Lost bid for #{player.name}",
                                  "Our offer to sign #{player.name} was rejected because there was a higher bidder.", Time.now)
        elsif not player_iterested_in_transfer(buyer_team, player) then
          bid.update(status: "PlayerRejected")
          buyer_team.send_message("The Chairman", "Lost bid for #{player.name}",
                                  "Our offer to sign #{player.name} was rejected because the player was not interested in moving to our club.", Time.now)
        elsif bid.amount < t.min_price then
          bid.update(status: "TeamRejected")
          buyer_team.send_message("The Chairman", "Lost bid for #{player.name}",
                                  "Our offer to sign #{player.name} was rejected by the seller.", Time.now)
        elsif not buyer_team.money >= bid.amount then
          bid.update(status: "InsufficientMoney")
          buyer_team.send_message("The Chairman", "Lost bid for #{player.name}",
                                  "Our bid to sign #{player.name} fell through because we did not have sufficient funds.", Time.now)
        else
          bid.update(status: "YouWon")
          t.update(status: 'Sold')
          buyer_team.update(money: buyer_team.money - bid.amount)
          seller_team&.update(money: seller_team.money + bid.amount)
          player.update(team_id: buyer_team.id)
          FormationPo.where(player_id: player.id).delete_all
          # update listing, marking sold
          sold = true
          puts "Team #{buyer_team.name} bought #{player.name} for #{bid.amount}"
          buyer_team.send_message("The Chairman", "New signing", "We have signed #{player.name} for €#{bid.amount}", Time.now)
          seller_team&.send_message("The Chairman", "Player sold", "We have sold #{player.name} to #{buyer_team.name} for €#{bid.amount}", Time.now)
        end
      end

      if sold == false then
        # always sell to someone ;)
        if seller_team != nil then
          puts "#{seller_team&.name} sold #{player.name} to outside team"
          seller_team.send_message("The Chairman", "Player sold", "We have sold #{player.name} for €#{t.min_price}", Time.now)
        end
        seller_team&.update(money: seller_team.money + t.min_price)
        FormationPo.where(player_id: player.id).delete_all
        player.update(team_id: nil)
        t.update(status: 'Sold')
      end
    end

    # nuke ancient transfer listings
    TransferListing.where("deadline < ?", Time.now - 60*60*24).destroy_all
  end

  def self.update_transfer_market()
    decide_transfer_market_bids
    # assume this is run once every 5 minutes by the server.
    if RngHelper.dice(1,10) == 1 then
      spawn_transfer_listing
    end
  end
end
