class UsersController < ApplicationController

  before_action :set_user, only: [:show, :edit, :update, :destroy, :messaging, :contacts, :customers, :transactions]
  load_and_authorize_resource except: [:customer_csv_template]
  include AdditionalUserActions

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
        redirect_to build_user_link
      elsif current_user.user_level == 1 && (current_user.business_name.blank? || current_user.rhombus_number.blank?) # incomplete merchant account
        # does this empty forms? check
        redirect_to "/profile"
      else
        if current_user.user_level == 0 && params[:captured_amt].present?
          #Transaction.process_captured_payment(@user, params) 
        elsif @user.user_level == 1 && @user.short_url.blank? && @user.rhombus_number.present? 
          # generate bitly link for merchant if blank and rhombus number exist...should remove this after twilio migration ###
          @user.short_url = UrlShortenerService.shorten_link("https://www.getrhombus.com/signup?referrer_num=#{@user.rhombus_number}&referrer=#{@user.business_name}")
          @user.save
        end
        @last4_transactions = @user.transactions.select(:created_at, :description, :notes).last(4).reverse
        @total_msgs = @user.get_total_messages
        @dashboard_stuff = @user.dashboard_stats 
        # @token = TextingService.get_twilio_capibility_token if current_user.user_level == 1       
      end           
    end
    delete_captured_payment_session
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

private
  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = current_user #User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :password, :first_name, :last_name, :phone_number,
      :card_name, :expiration_month, :expiration_year, :instrument_uri, :card_type, :street_address,
      :state_province, :country, :user_level)
  end

end