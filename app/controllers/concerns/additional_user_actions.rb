module AdditionalUserActions
  extend ActiveSupport::Concern

  def messaging
    if @user.user_level != 1
      redirect_to :root and return
    end
    # Generate bitly if blank
    if @user.short_url.blank?
      @user.short_url = UrlShortenerService.shorten_link("https://www.getrhombus.com/signup?referrer_num=#{@user.rhombus_number}&referrer=#{@user.business_name}")
      @user.save
    end
    render layout: 'application_dashboard_messaging'
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
     @contacts = @user.get_user_contacts.paginate(:page => params[:page], :per_page => 25)
  end

  def customers
    @customers = @user.get_user_customers.paginate(:page => params[:page], :per_page => 25)
  end

  def transactions
    @transactions = @user.get_user_transactions.paginate(:page => params[:page], :per_page => 25)
  end

  def build_user_link
    # if it includes a captured payment, also check if msg_id is present, tag_id is optional
    # referrer_num is the merchant the payment is going to
    link = session[:captured_amt].present? ? "/profile?amt=#{session[:captured_amt]}&referrer_num=#{session[:referrer_num]}" + 
                                          "&msg_id=#{session[:msg_id]}&tag_id=#{session[:tag_id]}" : "/profile" 
    delete_captured_payment_session
    link
  end

  def set_captured_payment_session
    session[:captured_amt] = params[:user][:captured_amt]
    session[:msg_id] = params[:user][:msg_id]
    session[:referrer_num] = params[:user][:referrer_num]
    session[:tag_id] = params[:user][:tag_id]
  end

  def delete_captured_payment_session
    session.delete(:captured_amt)
    session.delete(:referrer_num)
    session.delete(:tag_id)
    session.delete(:msg_id)
  end

end