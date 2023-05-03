class RemindersController < ApplicationController
  include DashboardNotification
  before_action :set_notifications, only: [:index]
  before_action :set_reminder, only: %i[change_status destroy]

  def index
    @reminders_tomorrow = current_user.reminders.includes(user_lists: [:customer_contact])
                                      .where('next_send_at >= ? and next_send_at < ?', Time.current.beginning_of_day + 1.days, Time.current.beginning_of_day + 2.days)
                                      .paginate(per_page: PAGINATION_PER_PAGE, page: params[:page]).order(created_at: :desc)
    @reminders_upcoming = current_user.reminders.includes(user_lists: [:customer_contact])
                                      .where('next_send_at >= ?', Time.current.beginning_of_day + 2.days)
                                      .paginate(per_page: PAGINATION_PER_PAGE, page: params[:page]).order(created_at: :desc)
    @reminders_today = current_user.reminders.includes(user_lists: [:customer_contact])
                                   .where('next_send_at >= ? and next_send_at < ?', Time.current, Time.current.beginning_of_day + 1.days)
                                   .paginate(per_page: PAGINATION_PER_PAGE, page: params[:page]).order(created_at: :desc)

    if @reminders_today.present? || @reminders_tomorrow.present? || @reminders_upcoming.present?
      respond_to do |format|
        format.js { render partial: 'index.js.erb' }
        format.html
      end
    else
      render 'empty_reminder'
    end
  end

  def change_status
    status = @reminder.active? ? 2 : 1
    if @reminder.update_attribute('status', status)
      @reminder.change_campaign_job
      flash[:notice] = 'Reminder status has been updated'
    else
      flash[:error] = @reminder.errors.full_messages
    end
    redirect_to user_reminders_path(current_user)
  end

  def destroy
    if @reminder.present?
      if @reminder.campaign_recipients.exists?
        flash[:error] = "You can only delete a reminder that hasn't run"
      else
        @reminder.destroy_campaign_jobs
        @reminder.destroy
        flash[:notice] = 'Reminder has been deleted'
      end
    else
      flash[:error] = 'Reminder does not exist'
    end
    redirect_to user_reminders_path(current_user)
  end

  private

  def set_reminder
    @reminder = current_user.reminders.find_by(id: params[:id])
  end
end
