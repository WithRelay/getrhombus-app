module AdditionalUserActions
  extend ActiveSupport::Concern

  [:verify_hosted_sms_order, :add_subscription, :add_card_info, :billing_information, :integrations].each do |method_name|
    send :define_method, method_name do
      # do nothing
    end
  end

  def add_profile_info
    @user = current_user
    @user.people = [@user.people.first || Person.new]
  end

  def rules
    @rules = current_user.rules
  end

  def business_settings
    current_user.address ||= Address.new
  end

  def account_settings
    if current_user.is_merchant?
      @user = current_user
      @user.people = [@user.people.first || Person.new]
    end
  end

  def remove_twitter_integration
    if current_user.twitter_cred.destroy
      flash[:notice] = 'Twitter integration removed successfully'
    else
      flash[:error] = 'Something went wrong'
    end
    redirect_to user_integrations_path(current_user)
  end

  def remove_stripe_integration
    if current_user.standalone_stripe_cred.destroy
      flash[:notice] = 'Stripe integration removed successfully'
    else
      flash[:error] = 'Something went wrong'
    end
    redirect_to user_integrations_path(current_user)
  end

  def sms_usage
    @amount_balance = Toolbox::Decimal.to_int_or_2dp current_user.account_balance
    @last4 = current_user.last4
    @card_type = current_user.card_type
  end

  def verify_hosted_sms
    response = HostedSmsService.post_verification(current_user.hosted_sms, params.permit(:VerificationCode))
    if response && response['status'] == 'verified'
      flash[:notice] = 'Your phone number has been verified'
      redirect_to user_path(current_user)
    else
      flash[:error] = response['message']
      redirect_to user_verify_hosted_sms_order_path(current_user)
    end
  end

  def add_to_merchant_customer_and_referrer_and_fb_cred
    # do this first so that in merchant customer, it can find a user's page specific id
    if params[:user][:page_specific_id].present?
      FbCred.where(page_specific_id: params[:user][:page_specific_id]).update_all(user_id: current_user.id)
      Conversation.update_conv_contact_to_user(params[:user][:page_specific_id], current_user)
    end

    if params[:user][:referrer_uid].present?
      if merchant = User.find_by(relay_uid: params[:user][:referrer_uid])
        Referrer.save_referrer_with_uid(merchant.relay_uid, current_user.id)
        MerchantCustomer.add_or_update_merchant_customer(merchant, current_user)
      end
    end
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

  def contact_csv_template
    render :template => "static_pages/to_404.html" and return if !current_user
    response = current_user.get_contact_csv_template
    if response
      respond_to do |format|
        format.csv { send_data response, filename: "contact_template.csv" }
      end
    else
      # use 500 page after it is built
      render :template => "static_pages/to_404.html"
    end
  end

end
