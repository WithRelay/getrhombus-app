module CampaignsHelper

  def channel_list(campaign)
    # Switching between channels is probably dangerous for persisted campaigns
    # Ex: Email content can't become sms
    if campaign.persisted?
      { campaign.channel => get_channel_enum_value(campaign) }
    else
      channels = { SMS: 0, MMS: 1, "Facebook Messenger" => 2, Email: 3}
      channels.delete(:MMS) if !current_user.can_send_mms?   # Twilio MMS support only in US, CA
      channels
    end
  end

  # enums normally return keys. we need the value for the dropdown
  def get_channel_enum_value(campaign)
    Campaign.channels[campaign.channel]
  end

  def is_one_time_checked?(campaign)
    campaign.frequency_type.blank? || campaign.frequency_type == 'one_time'
  end

  def is_recurring_checked?(campaign)
    campaign.frequency_type == 'recurring'
  end

  def repeat_days_options
    { 'Repeat every'=> 0, '7 days' => 7, '14 days' => 14, '30 days' => 30,
      '60 days' => 60, '90 days' => 90
    }
  end
end
