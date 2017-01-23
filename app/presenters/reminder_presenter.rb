class ReminderPresenter < BasePresenter
  def reminder_change_status_link
    return 'Inactive' if @model.inactive?
    text = @model.paused? ? 'Unpause' : 'Pause'
    h.link_to(text, change_status_user_reminder_path(@user, @model), method: :put, class: 'actions-button cancel')
  end
end
