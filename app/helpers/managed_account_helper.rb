module ManagedAccountHelper

  def url_for_create_update
    if current_user.stripe_creds.persisted.present?
      'update_managed_acct'
    else
      'create_managed_acct'
    end
  end

  def connect_org_type(account)
    if account.org_type.present?
      selected_org_type = {}
      business_type_list.each do |k, v| 
        if v == account.org_type
          selected_org_type[k] = v
          return selected_org_type
        end
      end 
    end

    business_type_list
  end

  def connect_country(user)
    country_list = PaymentService.stripe_country_list.collect{ |k,v| [v[0], k]}
    selected_country = country_list.select{ |country| country.include?(user.country.to_sym) if user.country.present? }
    selected_country[0].present? ? selected_country : country_list
  end
end
