class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]

  def new
  end

  def create
    auth = request.env["omniauth.auth"]

    user = User.find_or_initialize_by(yahoo_uid: auth.uid)
    user.email = auth.info.email || "#{auth.uid}@yahoo.com"
    user.access_token = auth.credentials.token
    user.refresh_token = auth.credentials.refresh_token
    user.token_expires_at = auth.credentials.expires_at ? Time.at(auth.credentials.expires_at) : nil
    user.save!

    session[:user_id] = user.id
    redirect_to root_path, notice: "Successfully authenticated with Yahoo!"
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "Signed out successfully."
  end

  def failure
    redirect_to root_path, alert: "Authentication failed: #{params[:message]}"
  end
end
