# presents camapgin object
class CampaignPresenter < BasePresenter

  # formats date time for campaign object as "2016/09/28 05:05 AM"
  def format_date_time
    @model.date_time.strftime('%Y/%m/%d %I:%H %p') if @model.date_time.present?
  end

  def count_recipient
    @model.lists.count
  end

  def campaign_change_status_link
    return 'Inactive' if @model.inactive?
    text = @model.paused? ? 'Unpause' : 'Pause'
    h.link_to(text, change_status_user_campaign_path(@user, @model), method: :put)
  end

  def show_info
    html = '<div class="alert alert-info"> <strong>Info!</strong> Sorry this campaign could not run.
            You need to complete facebook messenger association </div>'
    !@user.fb_pages.subscribed.present? && @model.facebook_messenger? ? html : ''
  end
end
