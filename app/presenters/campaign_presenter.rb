# presents camapgin object
class CampaignPresenter < BasePresenter
  include Rails.application.routes.url_helpers

  # formats date time for campaign object as "2016/09/28 05:05 AM"
  def format_date_time
    @model.date_time.strftime('%Y/%m/%d %I:%H %p') if @model.date_time.present?
  end

  def format_frequency_type
    @model.frequency_type.humanize.titleize
  end

  def generate_status_link
    return "- " if @model.status == 'inactive'
    text = @model.status == 'paused' ? 'Unpause' : 'Pause'
    link = change_status_user_campaign_path(@user, @model, new_status: text.downcase)
    "<a rel='nofollow' data-method='put' href='#{link}'>#{text} Campaign</a>".html_safe    
  end

end
