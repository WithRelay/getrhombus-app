class MobileCampaign

  def initialize(campaign, user_list=[])
    @campaign = campaign
    @user_list = user_list
    @message_obj = Message.new
    @failure_list = []
  end

  def send_failure
    media_link_urls = media_urls
    @user_list.each do |user|
      campaign_send = @message_obj.send_and_save_message(rn_type, merchant_rhombus_number, user.phone_number,
                                           message, media_link_urls)
      @failure_list.push(user) unless campaign_send && list.channel.present?
    end
    return @failure_list
  end

  def send_campaign
    @campaign.lists.each do |list|
      contact_list = list.contact?
      list.get_users.each do |customer|
        campaign_send = contact_list ? send_to_contact(customer[:user]) : send_to_customer(customer[:user])
        @failure_list.push(customer[:user]) if (!contact_list && campaign_send && list.channel.present?)
      end
    end
    return @failure_list
  end

  private

  def send_to_contact(merchant_contact_obj)
    contact_details = User.get_user_snapshot(merchant_contact_obj.uid, merchant_contact_obj.uid_type,
                                            @campaign.user.id)
    send_by_mobile(contact_details[:phone_number])
  end

  def send_to_customer(user_obj)
    send_by_mobile(user_obj.phone_number)
  end

  def send_by_mobile(phone_number)
    media_link_urls = media_urls
    Conversation.find_or_create_conversation_for_message_and_send_publish(
              @campaign.user, nil, customer[:user].uid,
              @campaign.text, customer[:user].uid_type)
  end

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
