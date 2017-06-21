class RemindersController < ApplicationController
  include DashboardNotification
  before_action :set_notifications, only: [:index, :edit]
  before_action :set_reminder, only: [ :edit, :update, :change_status , :destroy ]

  def index
    @reminder = params[:id].present? ? Reminder.find_by_id(params[:id]) : Reminder.new
    reminders = current_user.reminders.active
    @reminders_tomorrow = reminders.where("date_time >= ? AND date_time < ?", Time.current.beginning_of_day + 1.days, Time.current.beginning_of_day + 2.days)
                            .paginate(page: params[:reminders_tomorrow], per_page: PAGINATION_PER_PAGE).order(created_at: :desc)
    @reminders_upcoming = reminders.where("date_time >= ?", Time.current.beginning_of_day + 2.days)
                            .paginate(page: params[:reminders_upcoming], per_page: PAGINATION_PER_PAGE).order(created_at: :desc)
    @reminders_today = reminders.where("date_time >= ? AND date_time < ?",Time.current.beginning_of_day, Time.current.beginning_of_day + 1.days)
                         .paginate(page: params[:reminders_today], per_page: PAGINATION_PER_PAGE).order(created_at: :desc)
    unless (@reminders_today.present? || @reminders_tomorrow.present? || @reminders_upcoming.present?)
      render('empty_reminder', locals: { reminder: current_user.reminders.build })
    else
      respond_to do |format|
        format.js { render partial: 'index.js.erb' }
        format.html
      end
    end
  end

  def edit; end

  def update
    if @reminder.update(reminder_params)
      flash[:notice] = 'Reminders updated'
      @reminder.update_reminder_job
      redirect_to user_reminders_path(current_user)
    else
      flash[:error] = @reminder.errors.full_messages
      render :edit
    end
  end

  def change_status
    status = @reminder.active? ? 2 : 1
    if @reminder.update_attribute('status', status)
      @reminder.update_reminder_job
      flash[:notice] = 'Reminder updated successfully'
    else
      flash[:error] = @reminder.errors.full_messages
    end
    redirect_to user_reminders_path(current_user)
  end

  def destroy
    if @reminder.destroy
    redirect_to user_reminders_path, flash: { notice: 'Reminder deleted'}
    else
      flash[:error] = "Reminder cannot be deleted"
      return
    end
  end

  private

  def set_reminder
    @reminder = current_user.reminders.find(params[:id])
  end

  def reminder_params
    # enums are define as integer but params are in string and rails is not converting string to integer
    params.require(:reminder).permit(:channel, :repeat_days, :date_time, :frequency_type, :text).tap do |c|
                                    c[:channel] = c[:channel].to_i; c[:frequency_type] = c[:frequency_type].to_i
                                    c[:date_time] = c[:date_time].present? ? c[:date_time].in_time_zone(current_user.time_zone) : nil
                                   end
  end

end
