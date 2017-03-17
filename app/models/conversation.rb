class Conversation < ActiveRecord::Base
  include PrettyDate

  has_many :conversation_refs, dependent: :destroy
  has_many :fb_messages, through: :conversation_refs, source: :textable, source_type: 'FbMessage', dependent: :destroy
  has_many :messages, through: :conversation_refs, source: :textable, source_type: 'Message', dependent: :destroy
  belongs_to :merchant_conversation, class_name: "User"

  # Timezone should already be set when calling methods in this class.

  # plug in charges
  # profile snapshot -  remove the extra customer since in customer show

  # the user texting this merchant
  def user
    User.find_by(id: self.uid) if self.uid_type == "user"
  end

  def self.get_open_conversations_count(merchant_id)
  	where(merchant_id: merchant_id, resolution: nil).count
  	where(merchant_id: merchant_id).count
  end

  # Returns hash with users who sent a message to the given merchant in the last "num_days" days
  def self.get_open_conversations(merchant_id, page)
####convs = where(merchant_id: merchant_id, resolution: nil).paginate(page: page, per_page: 25)
  	convs = where(merchant_id: merchant_id).paginate(page: page, per_page: 5)
  	x = convs.map { |conv| conv.conversation_hash }
    # remove these lines and x
  	x.first[:profile_image] = { type: 'image', value: 'http://lorempixel.com/400/200/' } if x.present?
    x
	end

  def conversation_hash
    last_message = ConversationRef.where(conversation_id: self.id).last
    if last_message.present?
      last_message = last_message.textable
      last_message.text = 'image attached' if last_message.present? && last_message.text.blank? && last_message.images.exists?
    end

    {
      id: self.id,
      uid_type: self.uid_type,
      uid: self.uid,
      full_name: User.get_conversation_display_name(self.uid, self.uid_type),
      profile_image: User.check_profile_picture(user),
      last_message: last_message.blank? ? '' : last_message.text,
      last_message_ts: last_message.blank? ? 0 : last_message.created_at.to_i,
      last_message_type: last_message.class.name,
      ago: last_message.blank? ? "" : time_in_relative_form(last_message.created_at, 'short_format'),
      unread_count: ConversationRef.where(conversation_id: self.id, unread: true).count,
      #has_messenger:
    }
  end

	def self.get_conversation_messages(conv, page)
    customer = User.find_by(id: conv.uid) if conv.uid_type == "user"
		convs_refs = conv.conversation_refs.paginate(page: page, per_page: 7).includes(textable: [:images]).order(created_at: :desc, id: :desc)
		latest_messages = Array.new
		unread_ids = []

		convs_refs.each do |cr|
			unread_ids.push(cr.id) if cr.unread
			latest_messages.push(message_hash(conv, cr.textable, cr, customer, nil))
    end
    [latest_messages, unread_ids.join(",")]
	end

	def self.message_hash(conv, msg, conv_ref, customer, merchant=nil)
    # u = msg.user_id == conv.merchant_id ? merchant : customer
    u = conv_ref.source == 'customer' ? customer : merchant

    {
      id: msg.id,
      source: msg.user_id == conv.merchant_id ? "merchant" : 'customer',  # or conv_ref.source
      profile_image: User.check_profile_picture(u),
      text: (msg.text) ? msg.text : '',
      ts_day_of_the_week: msg.created_at.strftime("%B") + " " + msg.created_at.strftime("%d").to_i.ordinalize,
      ts_time: msg.created_at.strftime('%l:%M %P'),
      unread: msg.unread,
      images: msg.images.map { |i| { ref: conv_ref.id, url: i.avatar.url } },           # return small version here??
      channel: msg.class.name
  	}
	end

  def mark_messages_as_read(ids)
  	begin
	  	# this can be more efficient
	  	refs = ConversationRef.includes(:textable).where(id: ids.split(","), conversation_id: self.id)
	  	ActiveRecord::Base.transaction do
		  	refs.update_all(unread: false)
		  	sms_ary, messenger_ary = Array.new, Array.new
		  	refs.each { |r|	r.textable.class.name == "Message" ? sms_ary.push(r.textable.id) : messenger_ary.push(r.textable.id) }
		  	Message.where(id: sms_ary).update_all(unread: false)
		  	FbMessage.where(id: messenger_ary).update_all(unread: false)
		  end
		  true
		rescue StandardError => e
		 	false
		end
	end

  # uid can be user id, phone number or messenger id
  def self.send_message(conv, team, msg, channel, source, media = [])
    @conv = conv
    page_access_token = team.get_page_access_token
    from = (channel == "FbMessage") ? page_access_token : team.rhombus_number

    if @conv.uid_type == "user"
      customer = User.find_by(id: @conv.uid)
      to = (channel == "FbMessage") ? customer.get_customer_page_specific_id(page_access_token) : customer.phone_number
    else
      to = @conv.uid
    end

    msg_instance = channel.constantize.new

    # Relate message to files
    if media.present?
      media_ids = []
      media.map! do |m|
        media_ids.push(m.id)
        m.avatar.url
      end
      msg_instance.image_ids = media_ids
    end

    if msg_instance.send_and_save_message(team, customer, from, to, msg, false, media)
      re = find_or_create_conversation_for_message(team.id, @conv.uid_type, @conv.uid, msg_instance, false, source)
      msg_hash = message_hash(re[0], msg_instance, re[1], customer, team)
      [msg_hash, msg_instance, re.second]    # message hash, instance and message conv ref are needed
    else
      false
    end
  end

  # when sending by platform on behalf of merchant like automated messages (excludes sending from dashboard)
  def self.find_or_create_conversation_for_message_and_send_publish(team, customer, uid_type, uid, msg_to_send, channel, media = [])
    re = find_or_create_conversation(team.id, uid_type, uid)
    msg_ary = send_message(re, team, msg_to_send, channel, 'platform', media)
    if msg_ary
      RealtimeStreamService.publish_to_dashboard(re, msg_ary.third, team, customer, msg_ary.second)
      msg_ary.first.id
    else
      false
    end
  end

  # when receiving
  def self.find_or_create_conversation_for_message_and_publish(team, customer, uid_type, uid, msg_instance, unread)
    re = find_or_create_conversation_for_message(team.id, uid_type, uid, msg_instance, unread, 'customer')
    RealtimeStreamService.publish_to_dashboard(re[0], re[1], team, customer, msg_instance)
  end

  # find or create conversation and attach new message
  def self.find_or_create_conversation_for_message(team_id, uid_type, uid, msg_instance, unread, source)
    conv = find_or_create_conversation(team_id, uid_type, uid)
    conv_ref = conv.conversation_refs.create(textable: msg_instance, unread: unread, source: source)
    [conv, conv_ref]
  end

	# find the conversation or create one
  def self.find_or_create_conversation(team_id, uid_type, uid)
    return @conv if @conv.present?
    Conversation.find_by(merchant_id: team_id, uid_type: uid_type, uid: uid, resolution: nil) || Conversation.create(merchant_id: team_id, uid_type: uid_type, uid: uid)
  end

  # find conversation
  def self.find_last_conversation(team_id, uid_type, uid)
    where(merchant_id: team_id, uid_type: uid_type, uid: uid).last
  end

  def self.conversation_per_hour(merchant_id)
    merchant_conv = Conversation.where(merchant_id: merchant_id)
    return 0 unless merchant_conv.present?
    first_conv, last_conv = merchant_conv.first, merchant_conv.last
    time_diff = (last_conv.created_at - first_conv.created_at)/1.hours
    return 0 if time_diff.to_i = 0
    (merchant_conv.count/time_diff).round
  end

  def self.get_merchant_todays_unread_count(merchant_id, date)
    find_by_sql(["select count(cr.id) as count from conversations c inner join conversation_refs cr
                  on c.id = cr.conversation_id
                  where cr.unread = 1 and c.resolution is null or c.resolution = ''
                  and c.merchant_id = ? and c.created_at >= ? and source = 2", merchant_id, date]).first.count
  end

  def self.get_merchant_total_unread_msgs_count(merchant_id)
    find_by_sql(["select count(cr.id) as count from conversations c inner join conversation_refs cr
                  on c.id = cr.conversation_id
                  where cr.unread = 1 and c.resolution is null or c.resolution = ''
                  and c.merchant_id = ? and source = 2", merchant_id]).first.count
  end

  def self.get_last_customer_msg_from_last5_convs_today(merchant_id, date)
    find_by_sql(["SELECT b.id as id, a.textable_id, b.uid, b.uid_type, a.created_at as created_at,
                  CASE WHEN a.textable_type = 'Message' THEN 'SMS' ELSE 'messenger' END as channel
                  FROM conversation_refs a
                  INNER JOIN (
                    SELECT e.id as id, max(c.id) as cr_id, e.uid as uid, e.uid_type as uid_type
                    FROM conversation_refs c
                    INNER JOIN (
                      SELECT id, uid, uid_type from conversations d
                      where d.merchant_id = ? and d.resolution is null or
                      d.resolution = '' and d.created_at >= ? order by d.created_at desc, id desc limit 5
                      ) e ON e.id = c.conversation_id
                    where source = 2 GROUP BY c.conversation_id
                  ) b ON a.id = b.cr_id order by a.created_at desc, id desc", merchant_id, date])
  end

  def self.publish_test_conversation
    conversation = Conversation.first
    conv_ref = ConversationRef.first
    merchant = User.find 23
    customer = User.find 22
    msg = Message.find 280
    RealtimeStreamService.publish_to_dashboard(conversation, conv_ref, merchant, customer, msg)
  end
end
