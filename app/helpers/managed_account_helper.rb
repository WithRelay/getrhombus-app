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
      valid_org_type.each do |k, v| 
        if v.include?(account.org_type)
          if v.is_a? Array
            k = 'Organization'
            v = 'Company'
          end
          selected_org_type[k] = v
          return selected_org_type
        end
      end 
    end

    { 'Individual' => 'Individual', 'Organization' => 'Company' }
  end

  def valid_org_type
    { 'Individual' => 'Individual', 'Company' => ["Business", "Nonprofit",
                                                  "Education (K-12)", "Education (Universities & Colleges)"]
    }
  end

  def connect_country(user)
    country_list = PaymentService.stripe_country_list.collect{ |k,v| [v[0], k]}
    selected_country = country_list.select{ |country| country.include?(user.country.to_sym) if user.country.present? }
    selected_country[0].present? ? selected_country : country_list
  end
end
