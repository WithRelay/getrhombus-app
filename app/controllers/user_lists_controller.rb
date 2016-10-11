class UserListsController < ApplicationController

	def remove_user
		@user_list = UserList.where(list_id:params[:list_id],user_id:params[:user_id])
		@user_list.delete_all
   		redirect_to :controller => 'lists', :action => 'show', :id => params[:list_id]
	end

end
