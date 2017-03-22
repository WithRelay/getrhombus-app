class AlertsController < ApplicationController
  include DashboardNotification

  before_action :set_alert, only: [:show, :edit, :update, :destroy]
  before_action :set_notifications

  respond_to :html

  def index
    @alerts = Alert.all
    respond_with(@alerts)
  end

  def show
    respond_with(@alert)
  end

  def new
    @alert = Alert.new
    respond_with(@alert)
  end

  def edit
    @custom_welcome = current_user.custom_welcome
  end

  def create
    @alert = Alert.new(alert_params)
    @alert.save
    respond_with(@alert)
  end

  def update
    @alert.update(alert_params)
    current_user.update_attribute(:custom_welcome, params[:alert][:custom_welcome].strip)
    redirect_to notifications_user_path, notice: "Updated"  #respond_with(@alert)
  end

  def destroy
    @alert.destroy
    respond_with(@alert)
  end

  private
    def set_alert
      @alert = Alert.find_by(user_id: current_user.id) #Alert.find(params[:id])
    end

    def alert_params
      params.require(:alert).permit(:send_alert, :interval, :include_sms, :sms_number, :custom_welcome)
    end
end
