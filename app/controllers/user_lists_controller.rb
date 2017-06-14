class UserListsController < ApplicationController
  
  def remove_member
    cct = params[:list_type] == 'customer' ? 'MerchantCustomer' : "MerchantContact"
		@user_list = UserList.find_by(list_id: params[:list_id], customer_contact_id: params[:member_id], customer_contact_type: cct)
		@user_list.destroy
    flash[:notice] = "Member has been removed"
   	redirect_to controller: 'lists', action: 'show', id: params[:list_id]
	end

end
