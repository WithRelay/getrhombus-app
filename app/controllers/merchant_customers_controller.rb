class MerchantCustomersController < ApplicationController
  
  def customers
  	@customers = current_user.customers
  	@new_customer = User.new
  end

  def show
  end
end
