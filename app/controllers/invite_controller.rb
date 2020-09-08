# typed: true
require 'digest/md5'

class InviteController < ApplicationController
  def invited
    @invite = UserInvite.find_by(code: params[:code])
    @code = params[:code]
  end

  def redeem_invite
    back = "/invite/#{params[:code]}"
    invite = UserInvite.find_by(code: params[:code])

    if invite == nil
      flash[:notice] = 'That invite has already been reclaimed'
      redirect_to back
      return
    end

    if User.find_by(name: params[:username]).present?
      flash[:notice] = 'A user with that name already exists'
      redirect_to back
      return
    end

    # select a random team without a manager
    team_id = ActiveRecord::Base.connection.execute(
      "select id from teams t where not exists (select * from users u where u.team_id=t.id) order by random()"
    ).values()&.first&.first

    if team_id.nil?
      flash[:notice] = 'Oh no! There are no teams looking for managers right now!'
      redirect_to back
      return
    end

    invite.delete()
    team = Team.find(team_id)
    team.update(name: params[:team_name], money: 10000000)
    User.create(name: params[:username],
                team: team,
                secret: Digest::MD5.hexdigest(params[:password]))
  end
end
