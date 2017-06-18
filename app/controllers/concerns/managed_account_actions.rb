module ManagedAccountActions
  extend ActiveSupport::Concern

  def managed_acct
    @user.address || @user.build_address
    @user.bank_accounts.present? || @user.bank_accounts.build
    @user.stripe_creds.present? || @user.stripe_creds.build
    @user.people.present? || @user.people.build
    @user.people.each_with_index { |p,i| @user.people[i].address || @user.people[i].build_address }
    @image = @user.people.representative.first.image
  end

  def create_managed_acct
    if save_identity_doc
      check_user_validation = user_valid_to_update
      if check_user_validation.present?
        flash[:error] = check_user_validation
      else
        flash[:notice] = 'Account connected successfully'
      end
    else
      flash[:error] = "Unable to upload your verification document"
    end

    render :managed_acct
  end

  def update_managed_acct
    if save_identity_doc
      check_user_validation = user_valid_to_update
      if check_user_validation.present?
        flash[:error] = check_user_validation
      else
        flash[:notice] = 'Account updated'
      end
    else
      flash[:error] = "Unable to upload your verification document"
    end

    render :managed_acct
  end

  def save_identity_doc
    if image_params[:avatar].present?
      stripe_managed = StripeManagedAccountService.new(current_user, image_params)
      file_upload = stripe_managed.upload_file
      return false unless file_upload.is_a?(Stripe::FileUpload)
      person = @user.people.representative.first
      # some checks should go here
      person.image.destroy if person.image.present?
      person.image = Image.create(avatar: image_params[:avatar])
      person.update_column(:stripe_file_id, file_upload.id)
    end

    return true     
  end

  def user_valid_to_update
    check_account_create = user_managed_account
    if check_account_create.methods.include?(:message)
      check_account_create.message
    else
      @user.errors.full_messages if @user.errors.full_messages.present?
    end
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

  def save_managed_connect_acccount(account, bank_account)
    save_params = params_with_stripe(account, bank_account)
    unless params[:action] == 'update_managed_acct'
      account_keys = account.keys
      save_params[:stripe_creds_attributes]['0'].merge!({ secret: account_keys.secret,
                                                          publishable_key: account_keys.publishable
                                                        })
    end
    save_params
  end

  def params_with_stripe(account, bank_account)
    account_verification = account.verification
    stripe_params = full_user_params
    stripe_params[:stripe_creds_attributes]['0'].merge!({ 
                                                          account_verification: account.verification,
                                                          legal_entity_verification: account.legal_entity.verification,
                                                          account_id: account.id,
                                                          livemode: Rails.env.production?,
                                                          charges_enabled: account.charges_enabled,
                                                          transfers_enabled: account.transfers_enabled
                                                        })
    unless bank_account.methods.include?(:message)
      stripe_params[:bank_accounts_attributes]['0'].merge!({ stripe_bank_account_id: bank_account.id,
                                                             bank_name: bank_account.bank_name,
                                                             status: bank_account.status,
                                                             livemode: Rails.env.production?,
                                                             fingerprint: bank_account.fingerprint })
    end
    stripe_params
  end

  def image_params
    { avatar: params[:user][:people_attributes]['0'][:avatar] }
  end

end
