class MerchantCustomersController < ApplicationController
  include DashboardNotification
  before_action :set_notifications

  def customers
  	@customers = current_user.customers
  	@new_customer = User.new
  end

  def show
  end
end
