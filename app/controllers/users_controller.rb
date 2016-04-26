class UsersController < ApplicationController

  before_action :set_user, only: [:show, :edit, :update, :destroy, :messaging, :contacts, :customers, :transactions]

  load_and_authorize_resource

  def index
     @users = User.all  # paginate(:page => params[:page], :per_page => 10)
  end

  def new
    @user = User.new
  end

  def show
    if params[:graph].present?  # for graphs in user account
      @stats = @user.get_line_stats if params[:graph] == 'line'
      @stats = @user.get_area_stats if params[:graph] == 'area'
      render json: @stats.to_json
    else
      if current_user.user_level == 0 && current_user.customer_uri.blank? # incomplete customer account
        # in case it includes a captured payment
        link = params[:amt].present? ? "/profile?amt=#{params[:amt]}&referrer_num=#{params[:referrer_num]}&msg_id=#{params[:msg_id]}" : "/profile"  
        redirect_to link
      elsif current_user.user_level == 1 && (current_user.business_name.blank? || current_user.stripe_access_token.blank? || current_user.rhombus_number.blank?) # incomplete merchant account
        redirect_to "/profile"
      else
        if current_user.user_level == 0 && params[:amt].present? && params[:referrer_num].present? && params[:msg_id].present?
          #Transaction.process_captured_payment(@user, params[:amt], params[:referrer_num], params[:mid]) 
        elsif @user.user_level == 1 && @user.short_url.blank? && @user.rhombus_number.present? 
          # generate bitly link for merchant if blank and rhombus number exist...should remove this after twilio migration ###
          @user.short_url = UrlShortenerService.shorten_link("https://www.getrhombus.com/signup?referrer_num=#{@user.rhombus_number}&referrer=#{@user.business_name}")
          @user.save
        end
        @last4_transactions = @user.transactions.select(:created_at, :description, :notes).last(4).reverse
        @total_msgs = @user.get_total_messages
        @dashboard_stuff = @user.dashboard_stats 
        @token = TextingService.get_twilio_capibility_token if current_user.user_level == 1       
      end           
    end
  end  
  
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
  
  def create
    @user = User.new(user_params)
    respond_to do |format|
      if @user.save 
          format.html { redirect_to @user, notice: 'Welcome!' }
         	format.json { render action: 'show', status: :created, location: @user }
      else
       	format.html { render action: 'new' }
       	format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit    
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update_with_password(params)
        format.html { redirect_to @user, notice: 'Profile updated!' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'Account deleted' }
      format.json { head :no_content }
    end
  end
  
  # Need to dry up this view...move out these methods? some methods might not be needed
  # like transactions...usnt that already in the relations

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
        @message = Message.new
        @message.send_and_save_message(5, merchant.rhombus_number, params[:user_number], params[:message])
        if !@message.id.blank?
          render :json => Hash['success' => true, 'user_level' => merchant.user_level, 'profile_image' => ActionController::Base.helpers.asset_path('rhombus_icon_50x50.png'), 'ts_day_of_the_week' => @message.created_at.strftime('%A'), 'ts_time' => @message.created_at.strftime('%l:%M %P')].to_json
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

private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

end