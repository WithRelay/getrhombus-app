module ListsHelper
  def get_list_channel
    value = if params[:uid_type].present?
              params[:uid_type]
            elsif params[:action] == "leads_contacts" && params[:uid_type].nil?
              'sms'
            end
    return value
  end
end
