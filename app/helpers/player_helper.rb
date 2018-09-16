module PlayerHelper
  SILLY_WORDS = ["shocker", "nightmare", "tragedy", "debacle", "crisis"]
  INJURY_TYPE = ["knee injury", "sprained ankle", "hamstring injury", "concussion", "calf injury", "head injury", "dislocated shoulder"]

  def self.spawn_injuries
    # expected to be run every 5 minutes
    Team.pluck(:id).each{|team_id|
      # to get roughly 1 injury per 3.5 days
      # probability of injury per 5 minutes is:
      # 5minutes / 3.5days*24hrs*60minutes ~= 0.001
      if rand < 0.001 then
        spawn_injury_on_team(team_id)
      end
    }
  end

  def self.spawn_injury_on_team(team_id)
    injure_player_id = Player.where(team_id: team_id).pluck(:id).sample
    player = Player.find(injure_player_id)

    spawn_injury_on_player(player)
  end

  def self.spawn_injury_on_player(player, how: 'during training')
    if player.injury == 0 then
      # light injuries are common
      duration = if RngHelper.int_range(0,1) == 0 then RngHelper.dice(1,2) else RngHelper.dice(1,15) end
      player.update(injury: duration, form: 0)

      if player.team != nil then
        team = player.team
        type = INJURY_TYPE.sample
        Rails.logger.info "Player #{player.name} on team #{team.name} has been injured for #{player.injury} days."
        Message.send_message(team, "Head Coach", "Player injury", "#{player.name} has suffered a #{type} #{how}, and will need #{player.injury} days to recover.", Time.now)
        if duration > 4 then
          NewsArticle.create(title: "#{team.name}'s #{player.name} in #{type} #{SILLY_WORDS.sample}!",
                             body: "The player is unlikely to be fit to play for #{player.injury} days.",
                             date: Time.now)
        end
        # AI can update formation after injury
        AiManagerHelper.pick_team_formation(team)
      end
    end
  end

  def self.daily_cure_injury
    #ActiveRecord::Base.connection.execute("update players set injury=injury-1 where injury > 0")
    Player.where.not(injury: 0).all.each do |p|
      p.update(injury: p.injury-1, form: 0)
      if p.injury == 0 and p.team_id != nil then
        Message.send_message(Team.find(p.team_id), "Head Coach", "Player recovery",
                             "#{p.name} has fully recovered from injury and is fit to play", Time.now)
      end
    end
  end

  def self.daily_maybe_change_player_form
    Player.pluck(:id).each{|player_id|
      # change player form roughly once every 5 days
      if rand < 0.2 then
        Player.where(id: player_id).update_all(form: [0,0,1,1,2].sample)
      end
    }

    # generate training form reports for non-AI managers
    User.all.each {|user|
      _generate_form_report_message_for_team(user.team)
    }
  end

  def self._generate_form_report_message_for_team(team)
=begin
    player_evaluations = Player
      .joins(:formation_pos)
      .where(team_id: team.id, formation_pos: {formation_id: team.formation_id})
      .order("formation_pos.position_num")
      .pluck(:forename, :name, :form, :injury)
      .map{|forename,name,form,injury|
        form_evaluation = injury > 0 ? "Injured" :
                          ["Poor", "Good", "Very Good", "Excellent"][form + RngHelper.int_range(0,1)]
        "<tr><td>#{forename} #{name}</td><td>#{form_evaluation}</td></tr>"
    }

    subject = "Training performance assessments"
    # delete old training performance messages, otherwise the inbox gets a bit
    # stuffed...
    Message.where(team_id: team.id, subject: subject).delete_all
    team.send_message("Head Coach", subject,
        "<p>This is my assessment of the players&#8217; training performance today.</p>
        <p>&#8505; <em>Excellent player form can mean up to two bonus points for
        all player skills.</em></p>
        <table>
        <thead>
          <tr><th>Player</th><th>Performance</th></tr>
        </thead>
        <tbody>#{player_evaluations.join}</tbody>
        </table>",
      Time.now)
=end
  end

  def self.daily_develop_youth_players
    players = Player.where("age < 18").where.not(team_id: nil).all
    players.each {|player|
      if rand < 0.25 and player.skill / 5.0 < 8.6 then
        # increase the player's skills by 2 points
        2.times do
          which_skill = Player::ALL_SKILLS.sample.to_s
          v = player.method(which_skill).call()
          if v < 9 then
            player.method(which_skill + "=").call(v + 1)
          end
        end
        Rails.logger.info("Youth player #{player} has improved.")
        player.save
      end
    }
  end
end
