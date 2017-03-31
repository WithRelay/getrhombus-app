module ManagedAccountHelper

  def url_for_create_update
    if current_user.stripe_creds.present?
      'update_managed_acct'
    else
      'create_managed_acct'
    end
  end

  def connect_org_type(account)
    if account.org_type.present?
      selected_org_type = {}
      valid_org_type.each{|k, v| selected_org_type[k] = k if v.include?(account.org_type); }
      selected_org_type
    else
      { 'Individual' => 'Individual', 'Organization' => 'Organization' }
    end
  end

  def valid_org_type
    { 'Individual' => 'Individual', 'Organization' => ["Business", "Nonprofit",
                                                       "Education",
                                                       "[K12] Education [University & Colleges"]
    }
  end

  def connect_country(user)
    country_list = PaymentService.stripe_country_list.collect{ |k,v| [v[0], k]}
    selected_country = country_list.select{ |country| country.include?(user.country.to_sym) if user.country.present? }
    selected_country[0].present? ? selected_country : country_list
  end
end
