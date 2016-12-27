class MobileCampaign

  def initialize(campaign)
    @campaign = campaign
    @message_class = Message.new
  end

  def send_campaign
    rn_type = @campaign.user.rn_type; media_link_urls = media_urls
    merchant_rhombus_number = @campaign.user.rhombus_number; message = @campaign.text
    @campaign.lists.each do |list|
      list.user_lists.each do |customer|
        @message_class.send_and_save_message(rn_type, merchant_rhombus_number, customer.user.phone_number,
                                             message, media_link_urls)
      end
    end
  end

  private

  def media_urls
    @campaign.images.attachment.map{ |image| image.avatar.url }
  end
end
