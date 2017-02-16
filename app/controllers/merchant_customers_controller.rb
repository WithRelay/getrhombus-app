class MerchantCustomersController < ApplicationController
  
  def customers
  	@customers = current_user.customers
  	@new_customer = User.new
  end

  def show
  	@user = User.find_by_id(params[:id])
  	@merchant_customer = MerchantCustomer.find_by_customer_id(params[:id])
  	@transactions = Transaction.where(user_id: params[:id])
  end
end
