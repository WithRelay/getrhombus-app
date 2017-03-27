class AwayMessagesController < ApplicationController

  include DashboardNotification
  before_action :set_notifications

  def show
    away_message = current_user.away_message
    @away_message = away_message.present? ? away_message : current_user.build_away_message
  end

  def create
    @away_message = current_user.build_away_message(away_message_params)
    @away_message.save ? success_message_with_path : error_mesage_with_path
  end

  def update
    @away_message = current_user.away_message.update_attributes(away_message_params)
    @away_message ? success_message_with_path : error_mesage_with_path
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

  def away_message_params
    params.require(:away_message).permit(:enabled, :response, :mon_ct, :mon_ot, :tue_ct, :wed_ct,
                                         :wed_ot, :thurs_ct, :thurs_ot, :fri_ct, :fri_ot, :sat_ct,
                                         :sun_ct, :sun_ot)
  end
end
