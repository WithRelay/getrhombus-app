class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :configure_permitted_parameters, if: :devise_controller?

  rescue_from ActiveRecord::RecordNotUnique, with: :record_not_unique   # capture phone number duplicates on sign up page
  
  def after_sign_in_path_for(user)
     current_user
  end

  def after_update_path_for(user)
      current_user
  end

 rescue_from CanCan::AccessDenied do |exception|
    #redirect_to "/404.html"#, :alert => exception.message
    render :template => "static_pages/to_404"
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:email, :phone_number, 
        :password, :password_confirmation, :user_level) }
    devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:email, :password) }
    devise_parameter_sanitizer.for(:account_update) { |u| u.permit(:email, :current_password, 
      :password, :password_confirmation, :name, :instrument_uri, :last_four, 
      :expiration_month,  :expiration_year, :zip_code, :card_name, :card_type, 
      :phone_number, :business_name, :business_type, :street_address, :city, 
      :state_province, :business_phone, :country, :routing_number, :account_name, 
      :account_number, :account_type, :approve_payments_immediately, :country, 
      :tax_rate, :business_zip_code) }
  end

  def record_not_unique
    flash[:alert] = "The phone number you entered is already being used on rhombus :("
    redirect_to "/signup"
  end

end
