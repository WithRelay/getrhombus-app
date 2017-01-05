class MobileCampaign

  def initialize(campaign, user_list=[])
    @campaign = campaign
    @user_list = user_list
    @message_class = Message.new
    @failure_list = []
  end

  def send_failure
    media_link_urls = media_urls
    @user_list.each do |user|
      campaign_send = @message_class.send_and_save_message(rn_type, merchant_rhombus_number, user.phone_number,
                                           message, media_link_urls)
      @failure_list.push(user) unless campaign_send
    end
    return @failure_list
  end

  def send_campaign
    media_link_urls = media_urls
    @campaign.lists.each do |list|
      list.get_users.each do |customer|
        campaign_send = @message_class.send_and_save_message(rn_type, merchant_rhombus_number, customer[:user].phone_number,
                                             message, media_link_urls)
        @failure_list.push(customer[:user]) unless campaign_send && list.channel.present?
      end
    end
    return @failure_list
  end

  private

  def merchant_rhombus_number
    @campaign.user.rhombus_number
  end

  def message
    @campaign.text
  end

  def rn_type
    @campaign.user.rn_type
  end

  def media_urls
    @campaign.images.attachment.map{ |image| image.avatar.url }
  end
end
