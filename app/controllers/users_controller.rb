class UsersController < ApplicationController

  before_action :set_user, only: [:show, :edit, :update, :destroy, :messaging]

  load_and_authorize_resource

  def index
     @users = User.all #paginate(:page => params[:page], :per_page => 10)
     #user = User.new
     #@response = user.balanced_associate_token_with_customer
  end

  def new
    @user = User.new
  end

  def show
    if current_user.user_level == 0 && current_user.customer_uri.blank? 
      redirect_to "/profile"
    elsif current_user.user_level == 1 && current_user.business_name.blank? 
      redirect_to "/profile"
    elsif current_user.user_level == 1 && current_user.stripe_access_token.blank? 
      redirect_to "/profile"
    else
      #@todays_stuff = current_user.todays_stuff      
      @todays_stuff = current_user.transactions.paginate(:page => params[:page], :per_page => 2).order('created_at DESC')
    end    
  end  
  
  def messaging
    if @user.user_level != 1
      redirect_to :root and return
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
    render :json => Hash['success' => true, 'messages' => Message.get_user_messages_by_merchant(params[:user_id], params[:id], limit)].to_json 
  end
  
  # Marks all user messages sent to a merchant as read
  def mark_user_messages_for_merchant_as_read
    Message.mark_user_messages_for_merchant_as_read(params[:user_id], params[:id])
    render :json => Hash['success' => true].to_json 
  end
  
  # Sends a message to user on behalf of merchant
  def send_message_from_merchant
    if !params[:message].blank?
      user = User.find_by_id(params[:user_id])
      merchant = User.find_by_id(params[:id])
      if !user.blank? && !merchant.blank?
        @message = Message.new
        @message.send_and_save_message(5, merchant.rhombus_number, user.phone_number, params[:message])
        if !@message.id.blank?
          render :json => Hash['success' => true, 'user_level' => merchant.user_level, 'image_url' => ActionController::Base.helpers.asset_path('rhombus_icon_50x50.png'), 'ts_day_of_the_week' => @message.created_at.strftime('%A'), 'ts_time' => @message.created_at.strftime('%l:%M %P')].to_json
          return
        end
      end
    end
    render :json => Hash['success' => false].to_json
  end

private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

end

#  def update
 #   if @user.update_with_password(params[:user])
  #    flash[:success] = "Profile updated"
   #   sign_in @user
    #  redirect_to @user
    #else
     # render 'edit'
    #end
  #end
     #@user_books = UserBook.where(:user_id => current_user).paginate(:page => params[:page], :per_page => 10)  #find_all_by_user_id(@user.id, :include => [:book])   #find user's books for shelf view
    #@user_books_count = @user_books.count      #for shelf Nav count