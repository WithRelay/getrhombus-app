class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :update_presence_status
  around_action :set_time_zone, if: :current_user

  include CheckUserProfile

  def after_sign_in_path_for(resource)
    check_user_redirect || root_path
  end

  rescue_from CanCan::AccessDenied do |exception|
    #redirect_to "/404.html"#, :alert => exception.message
    render :template => "static_pages/to_404"
  end

  protected

  def update_presence_status
    if current_user.present? && current_user.is_merchant?
      pubnub = Pubnub.new(
        publish_key: Rails.application.secrets.pubnub["publish_key"],
        subscribe_key: Rails.application.secrets.pubnub["subscribe_key"],
        uuid: "uuid-#{current_user.id}",
        presenceTimeout: 120,
        heartbeatInterval: 30
      )
      if params[:controller] == 'conversations' && params[:action] == 'index'
        pubnub.subscribe(
          channels: ['messaging_' + Rails.env + '_' + current_user.id.to_s],
          with_presence: true
        )
      else
        pubnub.unsubscribe(
          channels: ['messaging_' + Rails.env + '_' + current_user.id.to_s],
          uuid: "uuid-#{current_user.id}"
        )
      end
    end
  end

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
      :time_zone, :org_type,
      address_attributes: [:street_address, :suite, :id, :city, :state_province, :postal_code, :country],
      people_attributes: [:id, :full_name]
    )}
  end
end
