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

  def managed_account_status(account)
    html_content = ''
    html_content += "<h5 class='account-status-text'>Charges Enabled: #{ yes_or_no account.charges_enabled }</h5>" if check_boolean_exist account.charges_enabled
    html_content += "<h5 class='account-status-text'>Transfers Enabled: #{ yes_or_no account.payouts_enabled }</h5>" if check_boolean_exist account.payouts_enabled
    
    if account.account_verification[:disabled_reason].present? || account.account_verification[:due_by].present? || account.account_verification[:fields_needed].present?
      html_content += "<h5 class='account-status-text'><strong>Account Status</strong></h5>"
      html_content += "<h5 class='account-status-text'>Disabled Reason: #{ humanize(account.account_verification[:disabled_reason]) }</h5>" if account.account_verification[:disabled_reason].present?
      html_content += "<h5 class='account-status-text'>Due By: #{ due_by(account) }</h5>" if account.account_verification[:due_by].present?
      html_content += "<h5 class='account-status-text'>Additional Information Needed: <ul> #{ additional_info account.account_verification[:fields_needed] } </ul> </h5>" if account.account_verification[:fields_needed].present?
    end

    if account.legal_entity_verification[:details].present? || account.legal_entity_verification[:details_code].present?
      html_content += "<h5 class='account-status-text'><strong>Legal Entity Status</strong></h5>"
      html_content += "<h5 class='account-status-text'>Status: #{ account.legal_entity_verification[:status] }</h5>"
      html_content += "<h5 class='account-status-text'>Details: #{ account.legal_entity_verification[:details] }</h5>" if account.legal_entity_verification[:details].present?
    end
    html_content.html_safe
  end

  def additional_info(fields)
    htm = ''
    fields.each do |field|
      if field == 'external_account'
        htm += "<li>#{humanize(field)} - You need to add a bank account</li>"
      elsif field == 'legal_entity.verification.document'
        htm += "<li>#{humanize(field)} - Please attach a government issued ID</li>"
      else
        htm += "<li>#{humanize(field)}</li>"
      end
    end
    htm
  end

  def humanize(obj)
    obj.gsub! '.', ' '
    obj.humanize.downcase
  end

  def check_boolean_exist(val)
    [true, false].include? val
  end

  def yes_or_no(val)
    (val == true) ? 'Yes' : 'No'
  end

  def due_by(account)
    due_by_date = Time.at(account.account_verification[:due_by]).in_time_zone(current_user.time_zone)
    "#{due_by_date.strftime('%a, %d %b %Y %H:%M:%S')} (#{current_user.time_zone})"
  end

  def managed_account_status_exists(account)
    check_boolean_exist(account.charges_enabled) || check_boolean_exist(account.payouts_enabled) || account.account_verification[:disabled_reason].present? || account.account_verification[:due_by].present? || account.account_verification[:fields_needed].present?
  end
end
