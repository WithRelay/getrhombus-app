module CheckUserProfile

  def check_user_redirect
    current_user.reload
    if current_user.is_customer?
      return build_user_link if current_user.card_id.blank?
      return user_transactions_path(current_user)
    else
      return user_add_profile_info_path(current_user) if current_user.org_name.blank?
      return user_add_subscription_path(current_user) if current_user.get_saas_subscription.blank?
      return user_add_rhombus_number_path(current_user) if current_user.rhombus_number.blank?
      return user_conversations_path(current_user)
    end
  end

end
