module CheckUserProfile

  def check_user_redirect(signin_signup = true)
    path = ""
    current_user.reload
    req_url = url_for controller: controller_name, action: action_name, only_path: true
    
    if current_user.is_customer?
      path = build_user_link if current_user.card_id.blank?
      path = user_transactions_path(current_user) if signin_signup
    else
      path = user_add_profile_info_path(current_user) if current_user.org_name.blank?      
      path = user_add_subscription_path(current_user) if current_user.get_saas_subscription.blank?
      path = user_add_rhombus_number_path(current_user) if current_user.rhombus_number.blank?
      path = user_conversations_path(current_user) if signin_signup
    end

    return "" if path.blank?
    parsed = URI::parse(path)
    parsed.fragment = parsed.query = nil
    req_url == parsed.to_s ? '' : path
  end

  def build_user_link
    # if it includes a captured payment, also check if msg_id is present, tag_id is optional
    # referrer_uid is the merchant the payment is going to
    path = user_add_card_info_path(current_user)
    if params[:user][:captured_amt].present?
      path = user_add_card_info_path(current_user, amt: params[:user][:captured_amt], referrer_uid: params[:user][:referrer_uid],
                                     msg_id: params[:user][:msg_id], tag_id: params[:user][:tag_id])
    end
    path
  end
end
