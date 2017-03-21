class Api::V1::ContactsController < API::V1::BaseController

  def index
    list = current_user.lists.find_by(id: params[:list_id])
    users = User.where('phone_number like ? AND id = ?', "#{params[:query]}%", current_user_id) |
            (MerchantContact.where(uid: merchant_contact_channel[list.channel],
            merchant_id: current_user_id))
    render json: users
  end

  private

  def merchant_contact_channel
    { 'sms' => 'phone_number', 'messenger' => 'messenger' }
  end
end
