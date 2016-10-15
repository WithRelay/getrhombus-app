# presents camapgin object
class CampaignPresenter < BasePresenter
  # formats date time for campaign object as "2016/09/28 05:05 AM"
  def format_date_time
    @model.date_time.strftime('%Y/%m/%d %I:%H %p') if @model.date_time.present?
  end

end
