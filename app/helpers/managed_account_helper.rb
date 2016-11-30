module ManagedAccountHelper

  def url_for_create_update
    if current_user.stripe_creds.managed.present?
      'update_managed_acct'
    else
      'create_managed_acct'
    end
  end
end
