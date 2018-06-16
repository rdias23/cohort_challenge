class OrdersController < ApplicationController
  def index
  	@orders = Order.all.includes(:user)
  end

  def import
  	Order.import(params[:file])

  	redirect_to root_url, notice: "Order Data imported!"
  end
end
