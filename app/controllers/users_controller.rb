class UsersController < ApplicationController

  # do I need these here ????
  before_action :set_user, only: [:show, :edit, :update, :destroy, :messaging, :contacts, :customers]

  # do i need this?
  load_and_authorize_resource except: [:customer_csv_template]
  
  include AdditionalUserActions

  def index
     @users = User.all  # paginate(:page => params[:page], :per_page => 10)
  end

  def new
    @user = User.new
  end

  def show
    handle_referrer_and_welcome_email
    if current_user.user_level == 0 && current_user.customer_uri.blank? # incomplete customer account
      redirect_to build_user_link
    elsif current_user.user_level == 1 && (current_user.org_name.blank? || current_user.rhombus_number.blank?) # incomplete merchant account
      # does this empty forms? check...i think so
      redirect_to "/profile"
    else
      Transaction.process_captured_payment(@user, params) if current_user.user_level == 0 && params[:captured_amt].present?
      @last4_transactions = @user.transactions.select(:created_at, :description, :notes).last(4).reverse
      @total_msgs = @user.get_total_messages
      @dashboard_stuff = @user.dashboard_stats 
      # @token = TextingService.get_twilio_capibility_token if current_user.user_level == 1     
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
    params.require(:user).permit(:id, :org_type, :org_name, :url, :org_tax_id, :description,
      address_attributes: [:id, :city, :street_address, :state_province, :country, :postal_code], 
      bank_accounts_attributes: [:id, :routing_number, :id, :country, :currency, :last4],
      people_attributes: [:id, :full_name, :dob, :last4, :role, :_destroy,
      address_attributes: [:street_address, :state_province, :id, :country, :postal_code, :state_province]],
      stripe_cred_attributes: [:id, :uid_type, :ip, :user_agent])
  end

  def handle_referrer_and_welcome_email
    Referrer.save_referrer_with_id(session[:referrer_id], current_user.id) if session[:referrer_id].present?
    Referrer.save_referrer_with_uid(session[:referrer_uid], current_user.id) if session[:referrer_uid].present?
    # Change this logic at some point
    # current_user.send_welcome_email if current_user.sign_in_count == 1
  end

end