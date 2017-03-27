class AwayMessagesController < ApplicationController

  include DashboardNotification
  before_action :set_notifications

  def show
    away_message = current_user.away_message
    @away_message = away_message.present? ? away_message : current_user.build_away_message
  end

  def create
    @away_message = current_user.build_away_message(message_params)
    @away_message.save ? success_message_with_path : error_mesage_with_path
  end

  def update
    @away_message = current_user.away_message
    @away_message.update_attributes(message_params) ? success_message_with_path : error_mesage_with_path
  end

  private

  def success_message_with_path
    flash[:notice] = 'Away message saved successfully'
    redirect_to user_away_message_path(current_user)
  end

  def error_mesage_with_path
    flash[:error] = 'Away message could not save'
    render :show
  end

  def message_params
    params.require(:away_message).permit(:enabled, :response, :mon_ct, :mon_ot, :tue_ct, :tue_ot,
                                         :wed_ct, :wed_ot, :thur_ct, :thur_ot, :fri_ct, :fri_ot,
                                         :sat_ct, :sat_ot, :sun_ct, :sun_ot)
  end
end
