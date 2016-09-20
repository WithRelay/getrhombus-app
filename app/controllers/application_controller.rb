class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  unless Proc.new {|c| c.request.original_url == root_url + "/facebook_webhook"}
    protect_from_forgery with: :exception
  end

  before_action :configure_permitted_parameters, if: :devise_controller?
  around_action :set_time_zone, if: :current_user

  # skip_before_action :authenticate_user!, :if => lambda { 
  #   if params[:object] && params[:object] == "page"
  #     false
  #   else
  #     true
  #   end
  # }

  # for uniquness check...can it be more specific...cos email, phone numbers are caught
  # capture phone number duplicates on sign up page
  rescue_from ActiveRecord::RecordNotUnique, with: :record_not_unique   
  
  def after_sign_in_path_for(user)
    current_user
  end

  def after_update_path_for(user)
    current_user
  end

  # Returns JSON object with the current user id
  def json_get_current_user
    render :json => Hash[
      success: current_user.present?, 
      id: current_user.present? ? current_user.id : nil,
      pubnub_publish_key: Rails.application.secrets.pubnub["publish_key"],
      pubnub_subscribe_key: Rails.application.secrets.pubnub["subscribe_key"],
      short_url: current_user.short_url,
      # Using a lightweight model...since all i need is to pass in current-user
      can_send_mms: UserPresenter.new(Plan.new, '', current_user).can_send_mms?
    ].to_json
  end

  rescue_from CanCan::AccessDenied do |exception|
    #redirect_to "/404.html"#, :alert => exception.message
    render :template => "static_pages/to_404"
  end

  protected

    def set_time_zone(&block)
      Time.use_zone(current_user.time_zone, &block)
    end

    def configure_permitted_parameters
      devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:email, :phone_number, :password, :user_level ) }
      devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:email, :password) }

      ### do we need these parameters here or in users_controller when updating account from settings page??
      devise_parameter_sanitizer.for(:account_update) { |u| u.permit(:email, #:current_password, 
        :password, :password_confirmation, :card_token, :last4, :exp_month,  :exp_year, 
        :card_name, :card_type, :rhombus_number, :update_rhombus_number, :phone_number, :org_name, 
        :org_category, :org_phone, :currency, :tax_percent, :url, :custom_welcome, :time_zone )}
    end

    def record_not_unique
      flash[:alert] = "The phone number you entered is already being used on rhombus :("
      redirect_to "/signup"
    end

end
