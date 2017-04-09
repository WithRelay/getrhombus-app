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
      pubnub_publish_key: Rails.application.secrets.pubnub["publish_key"],
      pubnub_subscribe_key: Rails.application.secrets.pubnub["subscribe_key"],
      short_url: current_user.short_url,
      first_name: current_user.first_name || 'there',
      num_of_chars: current_user.rn_type.present? ? 1500 : 150,
      customer_contact_count: MerchantCustomer.where(merchant_id: current_user.id).count + MerchantContact.where(merchant_id: current_user.id).count,
      can_accept_payments: current_user.can_accept_payments?(true),
      profile_image: User.check_profile_picture(current_user),
    }
  end

  rescue_from CanCan::AccessDenied do |exception|
    #redirect_to "/404.html"#, :alert => exception.message
    render :template => "static_pages/to_404"
  end


  protected

    def render_requested_format(obj)
      respond_to do |format|
        format.js { render partial: 'shared/index.js.erb', locals: { obj: obj } }
        format.html
      end
    end

    def set_time_zone(&block)
      Time.use_zone(current_user.time_zone, &block)
    end

    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up) { |u| u.permit(:email, :phone_number, :password, :user_level) }
      devise_parameter_sanitizer.permit(:sign_in) { |u| u.permit(:email, :password) }
      devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(:email, :current_password,
        :password, :password_confirmation, :last4, :exp_month,  :exp_year, :card_name, :card_type,
        :rhombus_number, :team_size, :use_rhombus_for, :rn_type, :rn_country, :phone_number, :card_id,
        :org_name, :org_category, :org_phone, :currency, :tax_percent, :url, :custom_welcome, :livemode,
        :time_zone, :zip_code, :state_province, :city, :street_address, :suite, :country, :org_type,
        people_attributes: [:id, :full_name]
      )}
    end
end
