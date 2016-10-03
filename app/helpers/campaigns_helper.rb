module CampaignsHelper
  def channel_list(campaign)
    channel_hash = { 'SMS'=> 0, 'MMS'=> 1, 'Facebook_Messenger'=> 2, 'Email'=> 3 }
    channel = campaign.channel
    if channel.present?
      channel_selected = { channel => channel_hash[channel] }
      channel_hash.delete(channel)
      Hash[channel_selected].merge(channel_hash)
    else
      channel_hash
    end
  end

  def is_one_time_checked?(campaign)
    camapaign_frquency = campaign.frequency_type
    if camapaign_frquency.present?
      camapaign_frquency == 'one_time'
    else
      return true
    end
  end

  def is_recurring_checked?(campaign)
    campaign.frequency_type == 'recurring'
  end
end
