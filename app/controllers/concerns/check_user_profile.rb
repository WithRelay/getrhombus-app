module CheckUserProfile

  def check_user_redirect(signin_signup = true)
    #return nil
    #path = nil
    current_user.reload
    req_url = url_for controller: controller_name, action: action_name, only_path: true
    
    if current_user.is_customer?
      unless current_user.has_valid_card?[:valid]
        path = build_user_link 
      else 
        path = user_transactions_path(current_user) if signin_signup
      end
    else
      if current_user.org_name.blank?      
        path = user_add_profile_info_path(current_user) 
      elsif current_user.get_saas_subscription.blank? && !current_user.is_platform?
        path = user_add_subscription_path(current_user) 
      elsif current_user.rhombus_number.blank? && !current_user.is_platform?
        path = user_add_rhombus_number_path(current_user)
      elsif restricted_routes.include? req_url && !current_user.is_platform?
        path = user_conversations_path(current_user)
      else
        path = user_conversations_path(current_user) if signin_signup
      end
    end

    return nil if path.blank?
    parsed = URI::parse(path)
    parsed.fragment = parsed.query = nil
    req_url == parsed.to_s ? '' : path
  end

  def restricted_routes
    [user_add_rhombus_number_path(current_user), user_add_subscription_path(current_user), user_add_rhombus_number_path(current_user)]
  end

  def build_user_link
    # if it includes a captured payment, also check if msg_id is present
    # referrer_uid is the merchant the payment is going to
    path = user_add_card_info_path(current_user)
    if params[:user].try(:[], :captured_amt).present?
      path = user_add_card_info_path(current_user, captured_amt: params[:user][:captured_amt],
                                     msg_id: params[:user][:msg_id], channel: params[:user][:channel])
    end
    path
  end
end
