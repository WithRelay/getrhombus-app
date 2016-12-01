module ManagedAccountHelper

  def url_for_create_update
    if current_user.stripe_creds.managed.present?
      'update_managed_acct'
    else
      'create_managed_acct'
    end
  end

  def connect_org_type(account)
    org_type = { 'Individual' => 'Individual', 'Organization' => 'company' }
    if account.org_type.present?
      selected_org_type = {}
      user_org_type = org_type.key(account.org_type)
      selected_org_type[user_org_type] = account.org_type
      selected_org_type
    else
      org_type
    end
  end

  def connect_country(user)
    country_list = PaymentService.stripe_country_list.collect{ |k,v| [v[0], k]}
    selected_country = country_list.select{ |country| country.include?(user.country.to_sym) }
    selected_country[0].present? ? selected_country : country_list
  end
end
