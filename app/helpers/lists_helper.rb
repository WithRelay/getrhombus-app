module ListsHelper
  def get_list_channel
    value = if params[:uid_type].present?
              params[:uid_type]
            elsif params[:action] == "leads_contacts" && params[:uid_type].nil?
              'sms'
            end
    return value
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
end
