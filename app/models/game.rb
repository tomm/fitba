require './app/simulation'

class Game < ActiveRecord::Base
  belongs_to :league
  belongs_to :home_team, :class_name => 'Team'
  belongs_to :away_team, :class_name => 'Team'
  
  def event_minutes(game_event)
    (90 * (game_event.time - self.start) / MATCH_LENGTH_SECONDS).to_i
  end

  def simulate(until_time)

    simulator = GameSimulator.new(self)
    simulator.simulate_until(until_time)

=begin
    raise "game must be in 'Scheduled' status" unless self.status == 'Scheduled'

    dice = lambda {|n,s|
      x=0
      (1..n).each do |_|
        x += 1 + (rand*s).to_i; 
      end
      x
    }
    player_skill = lambda {|p| p.shooting + p.passing + p.tackling + p.handling + p.speed }
    player_pos = lambda {|p,t| FormationPo.find_by(player_id: p.id, formation_id: t.formation_id) }
    team_players = lambda {|t| Player.joins(:formation_pos).where(team_id: t.id, formation_pos: {formation_id: t.formation_id}).all }
    find_skills = lambda {|players, team|
      skills = [0,0,0,0] # Gk, Defense, Mid, Attack
      players.each do |p|
        pos = player_pos.call(p, team)
        skill = player_skill.call(p)
        if pos.position_y == 6
          skills[0] += skill
        elsif pos.position_y == 5
          skills[1] += skill
        elsif pos.position_y == 4 # Defensive-mid
          skills[1] += skill / 2
          skills[2] += skill / 2
        elsif pos.position_y == 3
          skills[2] += skill
        elsif pos.position_y == 2 # attacking-mid
          skills[2] += skill / 2
          skills[3] += skill / 2
        elsif pos.position_y == 1
          skills[3] += skill
        else
          raise "Invalid player position: #{pos.position_x},#{pos.position_y}"
        end
      end
      skills
    }

    pick_shooter = lambda{|players|
      players.sample
    }

    # this time t1 = attacking team, t2 = defending team
    try_shot = lambda{|players_t1,players_t2,skill_t1,skill_t2|
      shooter = pick_shooter.call(players_t2)
      p "#{shooter.name} takes a shot!"
      dice.call(1,player_skill.call(shooter)) > dice.call(2,skill_t2[0])
    }

    # t1 = home team, t2 = away team
    calc_game = lambda {|players_t1,players_t2,skill_t1,skill_t2|
      #skills = [0,0,0,0] # Gk, Defense, Mid, Attack
      goals = [0, 0]
      position = 0 # midfield. 1=home (t1) attack, -1=away (t2) attack
      (1..90).each do |minute|
        if position == 0  # midfield
          diff = dice.call(1,skill_t1[2]) - dice.call(1,skill_t2[2])
          if diff > 0 then
            position = 1
          elsif diff < 0 then
            position = -1
          end
        elsif position == 1  # home attack
          diff = dice.call(1,skill_t1[3]) - dice.call(1,skill_t2[1])
          if diff > 0 then
            # try shot
            if try_shot.call(players_t1, players_t2, skill_t1, skill_t2)
              p "It's a goal!"
              goals[0] += 1
            else
              p "Miss."
            end
          elsif diff < 0 then
            position = 0
          end
        elsif position == -1  # away attack
          diff = dice.call(1,skill_t1[1]) - dice.call(1,skill_t2[3])
          if diff > 0 then
            position = 0
          elsif diff < 0 then
            # try shot
            if try_shot.call(players_t2, players_t1, skill_t2, skill_t1)
              p "It's a goal!"
              goals[1] += 1
            else
              p "Miss."
            end
          end
        else
          raise "invalid position #{position}"
        end
        p "#{minute}:00 #{position}, #{goals}"
      end
      goals
    }

    players_t1 = team_players.call(self.home_team)
    players_t2 = team_players.call(self.away_team)

    skill_t1 = find_skills.call(players_t1, self.home_team)
    skill_t2 = find_skills.call(players_t2, self.away_team)

    goals = calc_game.call(players_t1, players_t2, skill_t1, skill_t2)
    p skill_t1
    p skill_t2
    p goals
    self.update(status: "Played", home_goals: goals[0], away_goals: goals[1])

    TeamPos.new(self.home_team)
    TeamPos.new(self.away_team)
=end
  end
end
