class Conversation < ActiveRecord::Base
  include PrettyDate

  has_many :conversation_refs, dependent: :destroy
  has_many :fb_messages, through: :conversation_refs, source: :textable, source_type: 'FbMessage', dependent: :destroy
  has_many :messages, through: :conversation_refs, source: :textable, source_type: 'Message', dependent: :destroy
  belongs_to :merchant_conversation, class_name: "User"   
 
 # the user texting this merchant
  def user
    User.find_by(self.uid) if self.uid_type == "user"
  end

  def self.get_open_conversations_count(merchant_id)
  	where(merchant_id: merchant_id, message_resolution_id: nil).count
  	where(merchant_id: merchant_id).count
  end

  # Returns hash with users who sent a message to the given merchant in the last "num_days" days
  def self.get_open_conversations(merchant_id, page)
####convs = where(merchant_id: merchant_id, message_resolution_id: [nil, '']).paginate(page: page, per_page: 25)
  	convs = where(merchant_id: merchant_id).paginate(page: page, per_page: 25)
  	x = convs.map { |conv| conv.conversation_hash }
    # remove these lines and x
  	x.first[:profile_image] = { type: 'image', value: 'http://lorempixel.com/400/200/' } if x.present?
    x
	end

  def conversation_hash
    last_message = ConversationRef.where(conversation_id: self.id).last
    if last_message
      last_message = last_message.textable
      last_message.text = 'image attached' if last_message.text.blank? && last_message.images.exists?
    end
    
    {
      id: self.id,
      uid_type: self.uid_type,
      uid: self.uid,
      full_name: User.get_display_name(self.uid, self.uid_type),
      profile_image: User.check_profile_picture(user),
      last_message: last_message.blank? ? '' : last_message.text,
      last_message_ts: last_message.blank? ? 0 : last_message.created_at.to_i,
      last_message_type: last_message.class.name,
      ago: last_message.blank? ? "" : last_message.created_at.super_short,
      unread_count: ConversationRef.where(conversation_id: self.id, unread: true).count,
      #has_messenger: 
    }
  end

	def get_conversation_messages(page)
    customer = user
		convs_refs = self.conversation_refs.paginate(page: page, per_page: 25).includes(textable: [:images]).order(created_at: :desc)
		latest_messages = Array.new
		unread_ids = []

		convs_refs.each do |cr|
			unread_ids.push(cr.id) if cr.unread
			latest_messages.push(message_hash(cr.textable, cr.id, customer, nil))
    end
    [latest_messages, unread_ids.join(",")]
	end

	def message_hash(msg, ref_id, customer, merchant=nil)
    u = msg.user_id == self.merchant_id ? merchant : customer

    {
      id: msg.id,
      source: msg.user_id == self.merchant_id ? "merchant" : 'customer',
      profile_image: User.check_profile_picture(u),
      text: (msg.text) ? msg.text : '',
      ts_day_of_the_week: msg.created_at.strftime("%B") + " " + msg.created_at.strftime("%d").to_i.ordinalize,
      ts_time: msg.created_at.strftime('%l:%M %P'),
      unread: msg.unread,
      images: msg.images.map { |i| { ref: ref_id, url: i.avatar.url } },           # return small version here??
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
  def send_message(team, msg, channel, media = [])
		from = (channel == "FbMessage") ? "get messenger cred" : team.rhombus_number

    if self.uid_type == "user"
      customer = User.find_by(id: self.uid)
      to = (channel == "FbMessage") ? 'get messenger cred' : customer.phone_number
    else
      to = uid
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
			ref_id = find_or_create_conversation_for_message(team.id, self.uid_type, self.uid, msg_instance, false)
			message_hash(msg_instance, ref_id, customer, team)
		else
			false
		end
  end

	# find the conversation or create one
  def find_or_create_conversation(team_id, uid_type, uid)
  	return self if self.id.present?
  	Conversation.find_or_create_by(merchant_id: team_id, uid_type: uid_type, uid: uid, message_resolution_id: nil)
  end

  def find_or_create_conversation_for_message(team_id, uid_type, uid, msg, unread)
    conv = find_or_create_conversation(team_id, uid_type, uid)
    conv_ref = conv.conversation_refs.create(textable: msg, unread: unread)
    conv_ref.id
  end

  def self.get_merchant_todays_unread_count(merchant_id, date)
    find_by_sql(["select count(cr.id) as count from conversations c inner join conversation_refs cr on c.id = cr.conversation_id
                   where cr.unread = 1 and c.message_resolution_id is null and c.merchant_id = ? and c.created_at >= ?", merchant_id, date]).first.count
  end

  def self.get_last_msg_from_last5_convs(merchant_id, date)
    last_5_ary = Conversation.where("merchant_id = ? and created_at >= ? and message_resolution_id is null", merchant_id, date)
                              .select('id').order(created_at: :desc).limit(5)
    return [] if last_5_ary.blank?
    last_5_ary = Conversation.find_by_sql(["SELECT b.id as id, a.textable_id, b.uid, b.uid_type, b.created_at as created_at,
                                                CASE WHEN a.textable_type = 'Message' THEN 'SMS'
                                                ELSE 'messenger' 
                                                END as channel FROM conversation_refs a
                                               INNER JOIN (
                                                  SELECT e.id as id, max(c.textable_id) as textable_id, e.uid as uid, e.uid_type as uid_type, c.created_at as created_at
                                                  FROM conversation_refs c
                                                  INNER JOIN (
                                                    SELECT id, uid, uid_type from conversations d
                                                    where d.merchant_id = ? and d.message_resolution_id is null
                                                    and d.created_at >= ? order by d.created_at desc limit 5
                                                  ) e ON e.id = c.conversation_id
                                                  GROUP BY c.conversation_id 
                                                ) b ON a.textable_id = b.textable_id", merchant_id, date])
  end   

end
