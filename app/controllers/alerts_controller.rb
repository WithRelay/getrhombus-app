class AlertsController < ApplicationController
  include DashboardNotification

  before_action :set_alert, only: [:show, :edit, :update]
  before_action :set_notifications , only: [:edit]

  respond_to :html

  def show
    respond_with(@alert)
  end

  def edit
    @custom_welcome = current_user.custom_welcome
    @sms_numbers = @alert.sms_numbers.try(:join, ',')
    @emails = @alert.emails.try(:join, ',')
  end

  def create
    @alert = Alert.new(alert_params)
    @alert.save
    respond_with(@alert)
  end

  def update
    @alert.update(alert_params)
    current_user.update_attribute(:custom_welcome, params[:alert][:custom_welcome].strip)
    redirect_to user_notifications_path, notice: "Updated"  #respond_with(@alert)
  end

  private
    def set_alert
      @alert = Alert.find_or_create_by(user_id: current_user.id) { |a| a.emails = [current_user.email] }
    end

    def alert_params
      params.require(:alert).permit(:send_alert, :interval, :include_sms, :sms_numbers, :emails, :custom_welcome).tap do |p|
        p[:emails] = p[:emails].try(:split, ',')
        p[:sms_numbers] = p[:sms_numbers].try(:split, ',')        
        p[:sms_numbers].delete_if { |pn| User.unscoped.exists?(rhombus_number: pn.gsub('+', '')) } if p[:sms_numbers].present?
      end
    end
end
