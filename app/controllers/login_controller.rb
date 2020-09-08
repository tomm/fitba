# typed: true
require 'digest/md5'

class LoginController < ApplicationController
  def login
  end

  def try_login
    logger.info params[:username]
    logger.info params[:password]

    pw = Digest::MD5.hexdigest(params[:password])
    user = User.find_by(name: params[:username], secret: pw)
    if user then
      session_hash = Digest::MD5.hexdigest(pw + Time.new.to_s)
      cookies[:session] = session_hash
      Session.create(user_id: user.id, identifier: session_hash)
      redirect_to '/'
    else
      redirect_to '/login', notice: "Your username or password was wrong!"
    end
  end
end
