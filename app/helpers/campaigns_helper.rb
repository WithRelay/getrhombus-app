module CampaignsHelper

  def channel_list(campaign, list)
    # Switching between channels is probably dangerous for persisted campaigns
    # Ex: Email content can't become sms
    channel_list = { SMS: 0, MMS: 1, Email: 3, 'Facebook Messenger' => 2 }
    campaign_channel = campaign.channel=='facebook_messenger' ? 'Facebook Messenger' : campaign.channel
    if campaign.persisted?
      { campaign_channel => get_channel_enum_value(campaign.channel) }
    elsif list.present? && campaign.invalid?
      list_channel = list[0].channel == 'messenger' ? 'facebook_messenger' : list[0].channel
      if list_channel.present?
        { campaign_channel => get_channel_enum_value(list_channel) }
      else
        channel_list
      end
    else
      # if fb page subscription is not present mms channel will be not visible
      channel_list.delete('Facebook Messenger') unless current_user.fb_pages.subscribed.present?
      channel_list
    end
  end

  def reminder_channel(reminder)
    { SMS: 0, "Facebook Messenger" => 2 }
  end

  # enums normally return keys. we need the value for the dropdown
  def get_channel_enum_value(channel)
    Campaign.channels[channel]
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
