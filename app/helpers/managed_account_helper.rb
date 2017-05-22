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
    html_content += "<h5 class='account-status-text'>Transfers Enabled: #{ yes_or_no account.transfers_enabled }</h5>" if check_boolean_exist account.transfers_enabled
    html_content += "<h5 class='account-status-text'>Disabled Reason: #{ account.disabled_reason }</h5>" if account.disabled_reason.present?
    html_content += "<h5 class='account-status-text'>Due By: #{ due_by(account) }</h5>" if account.due_by.present?
    html_content += "<h5 class='account-status-text'>Additional Information Needed: <ul> #{ additional_info account.fields_needed } </ul> </h5>" if account.fields_needed.present?
    html_content.html_safe
  end

  def additional_info(fields)
    htm = ''
    fields.each do |field|
      if field == 'external_account'
        htm += "<li>external_account - You need to add a bank account</li>"
      elsif field == 'legal_entity.verification.document'
        htm += "<li>legal_entity.verification.document - Please attach a government issued ID</li>"
      else
        htm += "<li>#{field}</li>"
      end
    end
    htm
  end

  def check_boolean_exist(val)
    [true, false].include? val
  end

  def yes_or_no(val)
    (val == true) ? 'Yes' : 'No'
  end

  def due_by(account)
    Time.at(account.due_by).in_time_zone(current_user.time_zone)
  end

  def managed_account_status_exists(account)
    check_boolean_exist(account.charges_enabled) || check_boolean_exist(account.transfers_enabled) || account.disabled_reason.present? || account.due_by.present? || account.fields_needed.present?
  end
end
