module CampaignsHelper
  def channel_list(campaign)
    channel_hash = { 'SMS'=> 0, 'MMS'=> 1, 'Facebook_Messenger'=> 2, 'email'=> 3 }
    channel = campaign.channel
    if channel.present?
      channel_selected = { channel => channel_hash[channel] }
      channel_hash.delete(channel)
      Hash[channel_selected].merge(channel_hash)
    else
      channel_hash
    end
  end
end
