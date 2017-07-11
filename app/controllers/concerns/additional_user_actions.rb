module AdditionalUserActions
  extend ActiveSupport::Concern

  [:add_rhombus_number, :add_subscription, :add_card_info, :billing_information, :integrations].each do |method_name|
    send :define_method, method_name do
      # do nothing
    end
  end
  
  def add_profile_info
    @user = current_user
    @user.people = [@user.people.first || Person.new]
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

  def add_to_merchant_customer_and_referrer_and_fb_cred
    # do this first so that in merchant customer, it can find a user's page specific id
    if params[:user][:page_specific_id].present?
      FbCred.where(page_specific_id: params[:user][:page_specific_id]).update_all(user_id: current_user.id)
      Conversation.update_conv_contact_to_user(params[:user][:page_specific_id], current_user)
    end

    if params[:user][:referrer_uid].present?
      merchant = User.find_by(relay_uid: params[:user][:referrer_uid])
      if merchant
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

  def refer_business
    if params[:referrer].present?
      @referrer = Referrer.new(referrer_params)
      if @referrer.save
        flash[:notice] = 'Referral was successful'
      else
        flash[:error] = 'Referral failed'
      end
      redirect_to user_refer_business_path
    end
  end

  def referrer_params
    params.require(:referrer).permit(:referrer_email, :email, :phone_number, :country, :referrer_name, :org_name,
                                        :ip, :city, :region, :postal).tap do |r|
      r[:referrer_uid] = current_user.relay_uid
    end
  end

end
