class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  around_action :set_time_zone, if: :current_user

  include CheckUserProfile

  def after_sign_in_path_for(resource)
    check_user_redirect || root_path
  end

  # Returns JSON object with the current user id
  def get_current_user
    render :json => {
      success: current_user.present?,
      id: current_user.present? ? current_user.id : nil,
      user_number: current_user.present? ? current_user.rhombus_number : nil,
      pubnub_publish_key: Rails.application.secrets.pubnub["publish_key"],
      pubnub_subscribe_key: Rails.application.secrets.pubnub["subscribe_key"],
      short_url: current_user.short_url,
      full_name: current_user.card_name,
      num_of_chars: current_user.rn_type.present? ? 1500 : 150
    }
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
      devise_parameter_sanitizer.permit(:sign_up) { |u| u.permit(:email, :phone_number, :password, :user_level ) }
      devise_parameter_sanitizer.permit(:sign_in) { |u| u.permit(:email, :password) }
      devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(:email, :current_password,
        :password, :password_confirmation, :card_token,
        :last4, :exp_month,  :exp_year, :card_name, :card_type,
        :rhombus_number, :team_size, :use_rhombus_for, :rn_type, :rn_country,
        :phone_number, :org_name, :org_category, :org_phone, :currency,
        :tax_percent, :url, :custom_welcome, :time_zone, :zip_code,
        :state_province, :city, :street_address, :suite, :country, :org_type,
        people_attributes: [:id, :full_name]
      )}
    end
end
