class CampaignPresenter < BasePresenter

  def campaign_name
    "#{@model.name} (#{@model.status})"
  end

  def campaign_change_status_link
    return 'Inactive' if @model.inactive?
    text = @model.paused? ? 'Unpause' : 'Pause'
    h.link_to(text, change_status_user_campaign_path(@user, @model), method: :put)
  end

  def show_info
    html = '<div class="toaster-row-column-1 w-col w-col-11">
              <div class="shrink-text toaster-text">
                <strong>Info!</strong> Sorry this campaign could not run. You need to connect your facebook page.
              </div>
            </div>'
    !@user.get_page_access_token.present? && @model.facebook_messenger? ? html : ''
  end

  def channel_text
    if ['sms', 'mms'].include? @model.channel
      @model.channel.upcase
    elsif @model.channel == 'facebook_messenger'
      'Messenger'
    else
      'Email'
    end
  end
end
