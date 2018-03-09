class MobileCampaign

  def initialize(campaign, recipients)
    @campaign = campaign
    @failure_recipients = []
    @recipients = recipients
    @channel = ['sms', 'mms'].include?(campaign.channel) ? 'Message' : 'FbMessage'
  end

  def send_campaign
    if @campaign.lists.first.contact?
      @recipients.each { |r| send_by_mobile(nil, r.uid_type, r.uid) }
    else
      @recipients = @recipients.to_a
      customer_user_obj_list.each_with_index do |c, i| 
        @failure_recipients.push(@recipients.delete_at(i)) unless send_by_mobile(c, 'user', c.id)
      end
    end

    { recipients: @recipients, retry_list: @failure_recipients }
  end

  private

  def customer_user_obj_list
    user_ids = @recipients.map { |recipient| recipient.customer_id }
    User.where(id: user_ids)
  end


  def send_by_mobile(customer, uid_type, uid)
    Conversation.find_or_create_conversation_for_message_and_send_publish(@campaign.user, customer, uid_type, uid, @campaign.text, @channel, media_ary, 'campaign')
  end

  # 1. get number of messages per number (round up)
  # 2. build hash of number and count sent...once count exceeded, remove from hash.


  def media_ary
    @campaign.images.attachment
  end
end
