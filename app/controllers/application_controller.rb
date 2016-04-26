class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :configure_permitted_parameters, if: :devise_controller?

  # for uniquness check...can it be more specific...cos email, phone numbers are caught
  rescue_from ActiveRecord::RecordNotUnique, with: :record_not_unique   # capture phone number duplicates on sign up page
  
  def after_sign_in_path_for(user)
    current_user
  end

  def after_update_path_for(user)
    current_user
  end

  # Returns JSON object with the current user id
  def json_get_current_user
    render :json => Hash[
      'success' => !current_user.blank?, 
      'id' => !current_user.blank? ? current_user.id : nil,
      'pubnub_publish_key' => Rails.application.secrets.pubnub["publish_key"],
      'pubnub_subscribe_key' => Rails.application.secrets.pubnub["subscribe_key"],
      'short_url' => current_user.short_url
    ].to_json
  end

  rescue_from CanCan::AccessDenied do |exception|
    #redirect_to "/404.html"#, :alert => exception.message
    render :template => "static_pages/to_404"
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:email, :phone_number, 
        :password, :user_level, :is_active, :referrer_num, :subscription_type, :captured_amt, :msg_id) }
    devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:email, :password) }
    devise_parameter_sanitizer.for(:account_update) { |u| u.permit(:email, #:current_password, 
      :password, :password_confirmation, :instrument_uri, :last_four, 
      :expiration_month,  :expiration_year, :card_name, :card_type, 
      :rhombus_number, :update_rhombus_number,
      :phone_number, :business_name, :business_type, :street_address, :city, 
      :state_province, :business_phone, :country, :currency, :approve_payments_immediately, 
      :tax_rate, :business_zip_code, :first_name, :last_name, :is_active, :url,
      :subscription_type, :custom_welcome ) }
  end

  def record_not_unique
    flash[:alert] = "The phone number you entered is already being used on rhombus :("
    redirect_to "/signup"
  end

end
