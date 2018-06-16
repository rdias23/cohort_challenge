class UsersController < ApplicationController
  def index
  	@users = User.all.includes(:orders).order("csv_created_at ASC")
  end

  def import
  	User.import(params[:file])

  	redirect_to root_url, notice: "User Data imported!"
  end
end
