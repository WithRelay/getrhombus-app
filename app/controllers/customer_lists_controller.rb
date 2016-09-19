class CustomerListsController < ApplicationController

	def remove_user
		@customer_list = CustomerList.where(list_id:params[:list_id],user_id:params[:user_id])
		@customer_list.delete
   		redirect_to :controller => 'lists'
	end

end
