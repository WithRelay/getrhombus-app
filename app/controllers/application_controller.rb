class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :prepare_exception_notifier
  #before_action :check_current_user_and_path
  around_action :set_time_zone, if: :current_user

  include CheckUserProfile

  def after_sign_in_path_for(resource)
    check_user_redirect || root_path
  end

  rescue_from CanCan::AccessDenied do |exception|
    #ExceptionNotifier.notify_exception(exception, env: request.env, data: { message: "was doing something wrong"})
    redirect_to_404(exception.message)
  end
  
  rescue_from ActiveRecord::RecordNotFound do
    redirect_to_404("We're unable to find the requested record.")
  end

  protected

  def render_requested_format(obj)
    respond_to do |format|
      format.js { render partial: 'shared/index.js.erb', locals: { obj: obj } }
      format.html
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in) { |u| u.permit(:email, :password) }
    devise_parameter_sanitizer.permit(:sign_up) { |u| u.permit(:email, :phone_number, :password, :user_level) }
    devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(:email, :current_password, :password, 
      :password_confirmation, :last4, :exp_month,  :exp_year, :card_name, :card_type, :rhombus_number, :team_size, 
      :use_rhombus_for, :rn_type, :rn_country, :phone_number, :card_id, :org_name, :org_category, :org_phone, :currency, 
      :tax_percent, :url, :custom_welcome, :livemode, :time_zone, :org_type, people_attributes: [:id, :full_name],
      address_attributes: [:street_address, :suite, :id, :city, :state_province, :postal_code, :country]
    )}
  end

  private

  def redirect_to_404(message)
    redirect_to to_404_path, alert: message
  end

  def check_current_user_and_path
    # Avoid js or api json requests, forms, static pages and guest user
    if request.format.html? && request.get? && ['static_pages', 'knowledge_base_categories', 'knowledge_bases'].exclude?(controller_name) && current_user.present? 
      # target only pages users actually see.
      if params[:user_id].present? && current_user.id != params[:user_id].to_i
        redirect_to_404('Forbidden. That simple.')
      else
        redirect_path = check_user_redirect(false)
        redirect_to redirect_path if redirect_path.present?
      end
    end
  end

  def set_time_zone(&block)
    Time.use_zone(current_user.time_zone, &block)
  end

  def prepare_exception_notifier
    request.env["exception_notifier.exception_data"] = {
      current_user: current_user
    }
  end

end
