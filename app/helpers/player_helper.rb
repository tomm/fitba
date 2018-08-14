module PlayerHelper
  def self.spawn_injuries
    # expected to be run every 5 minutes
    Team.pluck(:id).each{|team_id|
      # to get roughly 1 unjury per week:
      # probability of injury per 5 minutes is:
      # 5minutes / 7days*24hrs*60minutes ~= 0.0005
      if rand < 0.0005 then
        spawn_injury_on(team_id)
      end
    }
  end

  def self.spawn_injury_on(team_id)
    injure_player_id = Player.where(team_id: team_id).pluck(:id).sample
    player = Player.find(injure_player_id)
    if player.injury == 0 then
      player.update(injury: RngHelper.dice(1,15))
      team = Team.find(team_id)
      puts "Player #{player.name} on team #{team.name} has been injured for #{player.injury} days."
      Message.send_message(team, "Head Coach", "Player injury",
                           "#{player.name} has suffered an injury during training", Time.now)
      # AI can update formation after injury
      AiManagerHelper.pick_team_formation(team)
    end
  end

  def self.daily_cure_injury
    #ActiveRecord::Base.connection.execute("update players set injury=injury-1 where injury > 0")
    Player.where.not(injury: 0).all.each do |p|
      p.update(injury: p.injury-1)
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
        Player.where(id: player_id).update_all(form: RngHelper.int_range(0,2))
      end
    }

    # generate training form reports for non-AI managers
    User.all.each {|user|
      _generate_form_report_message_for_team(user.team)
    }
  end

  def self._generate_form_report_message_for_team(team)
    player_evaluations = Player
      .joins(:formation_pos)
      .where(team_id: team.id, formation_pos: {formation_id: team.formation_id})
      .order("formation_pos.position_num")
      .pluck(:forename, :name, :form)
      .map{|forename,name,form|
        form_evaluation = ["Poor", "Good", "Very Good", "Excellent"][form + RngHelper.int_range(0,1)]
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
  end
end
