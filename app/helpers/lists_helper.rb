module ListsHelper
  def get_list_channel
    params[:uid_type].present? ? params[:uid_type] : 'sms'
  end

  def customer_contact_details(list_user)
    if @list.contact?
      User.get_user_snapshot(list_user.uid, list_user.uid_type, current_user.id)
    else
      list_user
    end
  end

  def list_show_partial
    if @list.contact?
      'list_contact'
    else
      'list_member'
    end
  end

  def customer_profile_path(customer_id)
    merchant_customer_id = MerchantCustomer.find_by(merchant_id: current_user.id, customer_id: customer_id).try(:id)
    "/users/#{current_user.id}/customers/#{merchant_customer_id}"
  end
end
