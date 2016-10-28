# presents camapgin object
class CampaignPresenter < BasePresenter
  include Rails.application.routes.url_helpers

  # formats date time for campaign object as "2016/09/28 05:05 AM"
  def format_date_time
    @model.date_time.strftime('%Y/%m/%d %I:%H %p') if @model.date_time.present?
  end

  def format_created_at
    h.time_ago_in_words(@model.created_at) + ' ago'
  end

  def format_frequency_type
    @model.frequency_type.humanize.titleize
  end

  def count_recipient
    @model.lists.count
  end

  def campaign_change_status_link
    return 'Inactive' if @model.inactive?
    text = @model.paused? ? 'Unpause' : 'Pause'
    h.link_to(text, change_status_user_campaign_path(@user, @model), method: :put)
  end

end
