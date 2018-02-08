module CampaignsHelper

  def channel_list(campaign, list)
    # Switching between channels is probably dangerous for persisted campaigns
    # Ex: Email content can't become sms
    channel_list = { SMS: 0, MMS: 1 } # , Email: 3 , 'Facebook Messenger' => 2 }
    if campaign.persisted?
      { format_campaign_channel(campaign.channel) => get_channel_enum_value(campaign.channel) }
    elsif list.present? && campaign.invalid? && list[0].contact?
      { format_campaign_channel(list[0].channel) => get_channel_enum_value(list[0].channel) }
    else
      # if merchant hasn't connect fb_page
      #unless current_user.get_page_access_token.present?
      #  channel_list.except('Facebook Messenger')
      #else
        return channel_list
      #end
    end
  end

  def format_campaign_channel(channel)
    return 'SMS' if channel == 'sms'
    return 'MMS' if channel == 'mms'
    return 'Email' if channel == 'email'
    'Facebook Messenger'
  end

  def reminder_channels
    channel_list = { SMS: 0 }#, "Facebook Messenger" => 2 }
    #unless current_user.get_page_access_token.present?
    #  channel_list.except("Facebook Messenger")
    #else
      return channel_list
    #end
  end

  def get_channel_enum_value(channel)
    channel = 'facebook_messenger' if channel == 'messenger'
    Campaign.channels[channel]
  end

  def is_one_time_checked?(campaign)
    campaign.frequency_type.blank? || campaign.frequency_type == 'one_time'
  end

  def is_recurring_checked?(campaign)
    campaign.frequency_type == 'recurring'
  end

  def repeat_days_options
    { 'Repeat every'=> 0, '7 days' => 7, '14 days' => 14, '30 days' => 30, '60 days' => 60, '90 days' => 90 }
  end

  def campaign_last_sent(campaign)
    last_sent = campaign.campaign_recipients.last
    last_sent.present? ? time_in_relative_form(last_sent.created_at, 'long_format') : "-"
  end
end
