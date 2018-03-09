class MobileCampaign

  def initialize(campaign, recipients)
    @campaign = campaign
    @merchant = @campaign.user
    @failure_recipients = []
    @recipients = recipients
    @channel = ['sms', 'mms'].include?(campaign.channel) ? 'Message' : 'FbMessage'

    # currently only works for countries (u.s, canada) whose area codes are in position 1--3
    @recipients_per_number = (@recipient.count/(@merchant.numbers.count.to_f)).ceil
    @number_area_code_hash = @merchant.numbers.map { |n| [n.number, n.number[1..3]] }.to_h
    @number_send_count_hash = @merchant.numbers.map { |n| [n.number, 0] }.to_h
  end

  def send_campaign
    number = nil
    if @campaign.lists.first.contact?
      @recipients.each do |r|

        if @channel == 'Message'
          number = @number_area_code_hash.key(r.uid[1..3])                        # find number to use by area code of recipient number
          number = @number_send_count_hash.first.first unless number              # if no match above, grab first merchant number
        end

        send_by_mobile(nil, r.uid_type, r.uid, number, number) 

        if @channel == 'Message'
          @number_send_count_hash[number] = @number_send_count_hash[number] + 1   # increase counter
          if @number_send_count_hash[number] == @recipients_per_number            # check that max send per number hasnt been exceeded else remove from hashes
            @number_area_code_hash.delete(number)
            @number_send_count_hash.delete(number)
          end
        end

      end
    else
      @recipients = @recipients.to_a
      customer_user_obj_list.each_with_index do |c, i| 
        
        if @channel == 'Message'
          number = @number_area_code_hash.key(c.phone_number[1..3])                 # find number to use by area code of recipient number
          number = @number_send_count_hash.first.first unless number                # if no match above, grab first merchant number
        end
        
        @failure_recipients.push(@recipients.delete_at(i)) unless send_by_mobile(c, 'user', c.id, number)

        if @channel == 'Message'
          @number_send_count_hash[number] = @number_send_count_hash[number] + 1     # increase counter
          if @number_send_count_hash[number] == @recipients_per_number              # check that max send per number hasnt been exceeded else remove from hashes
            @number_area_code_hash.delete(number)
            @number_send_count_hash.delete(number)
          end
        end

      end

    end

    { recipients: @recipients, retry_list: @failure_recipients }
  end

  private

  def customer_user_obj_list
    user_ids = @recipients.map { |recipient| recipient.customer_id }
    User.where(id: user_ids)
  end

  def send_by_mobile(customer, uid_type, uid, from)
    Conversation.find_or_create_conversation_for_message_and_send_publish(@merchant, customer, uid_type, uid, @campaign.text, @channel, media_ary, 'campaign', from)
  end

  def media_ary
    @campaign.images.attachment
  end
end
