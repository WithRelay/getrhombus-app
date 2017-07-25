class Api::V1::UserListsController < API::V1::BaseController
  
  def index
    user_lists = UserList.joins(:list)
                          .where(customer_contact_type: params[:customer_contact_type], customer_contact_id: params[:customer_contact_id])
                          .where('lists.campaign_type = ?', List.campaign_types[:campaign]) 
                          .select("lists.id as id, name, user_lists.created_at")

    render json: user_lists.map { |ul| { id: ul.id, name: ul.name, user_added: ul.user_added } }
  end

  def create
    unless UserList.exists?(user_list_params)
      user_list = UserList.new(user_list_params)
      if user_list.save
        render json: { message: 'Member has been added', user_added: user_list.user_added }
      else
        render json: { message: 'Unable to add member to list' }, status: 500
      end
    else
      render json: { message: 'Member is already a part of this list' }, status: 500
    end
  end

  private

  def user_list_params
    params.require(:user_list).permit(:customer_contact_id, :customer_contact_type, :list_id)
  end

end
