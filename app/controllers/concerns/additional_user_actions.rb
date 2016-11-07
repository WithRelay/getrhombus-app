module AdditionalUserActions
  extend ActiveSupport::Concern

  def messaging
    redirect_to :root and return if @user.user_level != 1

    # change back
    render layout: 'application_dashboard_messaging'
    #render layout: 'xxx'
  end

  def managed_acct
    @user.address || @user.build_address
    @user.bank_accounts.present? || @user.bank_accounts.build
    @user.stripe_creds.present? || @user.stripe_creds.build
    @user.people.present? || @user.people.build
    @user.people.each_with_index { |p,i| @user.people[i].address || @user.people[i].build_address }
  end

  def create_managed_acct
    params[:user][:org_type] = 'Business' if params[:user][:org_type] == 'Company' && current_user.org_type == 'Individual'
    current_user.update(user_params)
    render json: {}
  end

  # Returns JSON object with user hash who sent a message to the given merchant in the last CONFIG[:dashboard]['messaging']['num_days_history'] days
  def json_get_latest_active_messaging
    render :json => Hash['success' => true, 'users' => User.get_latest_active_messaging(params[:id], CONFIG[:dashboard]['messaging']['num_days_history'])].to_json 
  end
  
  # Returns JSON object with the last x messages a user has sent to the given merchant
  def json_get_user_messages_by_merchant
    if params[:limit]
      limit = params[:limit]
    else
      limit = CONFIG[:dashboard]['messaging']['num_messages_per_user_default']
    end
    render :json => Hash['success' => true, 'messages' => Message.get_user_messages_by_merchant(params[:user_number], params[:id], limit)].to_json 
  end
  
  # Marks all user messages sent to a merchant as read
  def mark_user_messages_for_merchant_as_read
    Message.mark_user_messages_for_merchant_as_read(params[:user_number], params[:id])
    render :json => Hash['success' => true].to_json 
  end
  
  # Sends a message to user on behalf of merchant
  def send_message_from_merchant
    if !params[:message].blank?
      merchant = User.find_by_id(params[:id])
      if !merchant.blank?
        message = Message.send_and_save_message(merchant.rhombus_number, params[:user_number], params[:message])
        if message
          render :json => Hash['success' => true, 'user_level' => merchant.user_level, 'profile_image' => ActionController::Base.helpers.asset_path('rhombus_icon_50x50.png'), 'ts_day_of_the_week' => message.created_at.strftime('%A'), 'ts_time' => message.created_at.strftime('%l:%M %P')].to_json
          return
        end
      end
    end
    render :json => Hash['success' => false].to_json
  end

  def contacts
    if current_user.user_level == 0
      @contacts = @user.get_customer_contacts.paginate(:page => params[:page], :per_page => 25)
    else
      @contacts = @user.get_merchant_contacts.paginate(:page => params[:page], :per_page => 25)
    end
  end

  def customers
    @customers = @user.get_merchant_customers.paginate(:page => params[:page], :per_page => 25)
  end

  def businesses
    @businesses = @user.get_customer_businesses.paginate(:page => params[:page], :per_page => 25)
  end

  def build_user_link
    # if it includes a captured payment, also check if msg_id is present, tag_id is optional
    # referrer_num is the merchant the payment is going to
    link = session[:captured_amt].present? ? "/profile?amt=#{session[:captured_amt]}&referrer_id=#{session[:referrer_id]}" + 
                                          "&msg_id=#{session[:msg_id]}&tag_id=#{session[:tag_id]}" : "/profile" 
    delete_captured_payment_session
    link
  end

  def set_captured_payment_session
    session[:captured_amt] = params[:user][:captured_amt]
    session[:msg_id] = params[:user][:msg_id]
    session[:referrer_id] = params[:user][:referrer_id]
    session[:referrer_uid] = params[:user][:referrer_uid]
    session[:tag_id] = params[:user][:tag_id]
  end

  def delete_captured_payment_session
    session.delete(:captured_amt)
    session.delete(:referrer_id)
    session.delete(:referrer_uid)
    session.delete(:tag_id)
    session.delete(:msg_id)
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

end