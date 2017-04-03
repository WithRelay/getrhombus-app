module AdditionalUserActions
  extend ActiveSupport::Concern

  def integrations
  end

  def business_information
  end

  def remove_twitter_integration
    if current_user.twitter_cred.destroy
      flash[:notice] = 'Twitter integration removed successfully'
    else
      flash[:error] = 'Something went wrong'
    end
    redirect_to integrations_user_path(current_user)
  end

  def remove_stripe_integration
    if current_user.standalone_stripe_cred.destroy
      flash[:notice] = 'Stripe integration removed successfully'
    else
      flash[:error] = 'Something went wrong'
    end
    redirect_to integrations_user_path(current_user)
  end

  def managed_acct
    @user.address || @user.build_address
    @user.bank_accounts.present? || @user.bank_accounts.build
    @user.stripe_creds.present? || @user.stripe_creds.build
    @user.people.present? || @user.people.build
    @user.people.each_with_index { |p,i| @user.people[i].address || @user.people[i].build_address }
  end

  def create_managed_acct
    check_user_validation = user_valid_to_update
    if check_user_validation.present?
      flash[:error] = check_user_validation
    else
      flash[:notice] = 'Account connected susseccfully'
    end
    managed_acct
    render :managed_acct
  end

  def user_managed_account
    stripe_managed = StripeManagedAccountService.new(current_user, full_user_params)
    action = { 'create_managed_acct'=> [:create_account, :create_external_account],
               'update_managed_acct'=> [:update_account, :check_update_or_create] }
    account = stripe_managed.send(action[params[:action]][0])
    if account.is_a?(Stripe::Account)
      external_account = stripe_managed.send(action[params[:action]][1], account)
      @user.update(save_managed_connect_acccount(account, external_account))
      external_account.is_a?(Stripe::BankAccount) ? account : external_account
    else
      account
    end
  end

  def update_managed_acct
    check_user_validation = user_valid_to_update
    if check_user_validation.present?
      flash[:error] = check_user_validation
    else
      flash[:notice] = 'User updated'
    end
    managed_acct
    render :managed_acct
  end

  def save_managed_connect_acccount(account, bank_account)
    account_keys = account.keys
    save_params = params_with_stripe(account, bank_account)
    unless params[:action] == 'update_managed_acct'
      save_params[:stripe_creds_attributes]['0'].merge!({ secret: account_keys.secret,
                                                          publishable_key: account_keys.publishable
                                                        })
    end
    save_params
  end

  def user_valid_to_update
    check_account_create = user_managed_account
    if check_account_create.methods.include?(:message)
      check_account_create.message
    else
      @user.errors.full_messages if @user.errors.full_messages.present?
    end
  end

  def params_with_stripe(account, bank_account)
    account_verification = account.verification
    stripe_params = full_user_params
    stripe_params[:stripe_creds_attributes]['0'].merge!({ disabled_reason: account_verification.disabled_reason,
                                                          due_by: account_verification.due_by,
                                                          fields_needed: account_verification.fields_needed,
                                                          account_id: account.id
                                                        })
    unless bank_account.methods.include?(:message)
      stripe_params[:bank_accounts_attributes]['0'].merge!({ stripe_bank_account_id: bank_account.id,
                                                             bank_name: bank_account.bank_name,
                                                             status: bank_account.status,
                                                             fingerprint: bank_account.fingerprint })
    end
    stripe_params
  end

  def build_user_link
    # if it includes a captured payment, also check if msg_id is present, tag_id is optional
    # referrer_uid is the merchant the payment is going to
    path = add_card_info_user_path(current_user)
    if params[:user][:captured_amt].present?
      path = add_card_info_user_path(current_user, amt: params[:user][:captured_amt], 
                                                   referrer_uid: params[:user][:referrer_uid],
                                                   msg_id: params[:user][:msg_id], tag_id: params[:user][:tag_id]) 
    end
    path
  end

  # using this to hold data till we get to transactions page for customer
  # could rebuild the link but we don't want users refreshing the page and trigerring more payments
  # since i will delete this session data the first time
  def set_captured_payment_session
    session[:captured_amt] = params[:user][:captured_amt]
    session[:msg_id] = params[:user][:msg_id]
    session[:referrer_uid] = params[:user][:referrer_uid]
    session[:tag_id] = params[:user][:tag_id]
  end

  def delete_captured_payment_session
    session.delete(:captured_amt)
    session.delete(:referrer_uid)
    session.delete(:tag_id)
    session.delete(:msg_id)
  end

  def add_or_update_user_referrer
    Referrer.save_referrer_with_uid(params[:user][:referrer_uid], current_user.id) if params[:user][:referrer_uid].present?
  end

  def customer_csv_template
    render :template => "static_pages/to_404.html" and return if !current_user
    response = current_user.get_customer_csv_template
    if response
      respond_to do |format|
        format.csv { send_data response, filename: "customer_template.csv" }
      end
    else
      # use 500 page after it is built
      render :template => "static_pages/to_404.html"
    end
  end

  def refer_business
    if params[:referrer].present?
      @referrer = Referrer.new(referrer_params)
      if @referrer.save
        flash[:notice] = 'Referral was successful'
      else
        flash[:error] = 'Referral failed'
      end
      redirect_to refer_business_user_path
    end
  end

  def referrer_params
    params.require(:referrer).permit(:referrer_email, :email, :phone_number, :country, :referrer_name, :org_name,
                                        :ip, :city, :region, :postal).tap do |r|
      r[:referrer_uid] = current_user.relay_uid
    end
  end
  
end
