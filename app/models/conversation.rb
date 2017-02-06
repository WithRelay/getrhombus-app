class Conversation < ActiveRecord::Base
  include PrettyDate

  has_many :conversation_refs, dependent: :destroy
  has_many :fb_messages, through: :conversation_refs, source: :textable, source_type: 'FbMessage', dependent: :destroy
  has_many :messages, through: :conversation_refs, source: :textable, source_type: 'Message', dependent: :destroy
  belongs_to :merchant_conversation, class_name: "User"

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

    if self.uid_type == "user"
      customer = User.find_by(id: self.uid)
      full_name = (customer) ? customer.card_name : ""
    else 
      # does fb at least give us some info?
      full_name = (self.uid_type == 'fb_page') ? "messenger user" : self.uid
    end

    {
      id: self.id,
      uid_type: self.uid_type,
      uid: self.uid,
      full_name: full_name || "",
      profile_image: User.check_profile_picture(customer),
      last_message: last_message.blank? ? '' : last_message.text,
      last_message_ts: last_message.blank? ? 0 : last_message.created_at.to_i,
      last_message_type: last_message.class.name,
      ago: last_message.blank? ? "" : last_message.created_at.super_short,
      unread_count: ConversationRef.where(conversation_id: self.id, unread: true).count
    }
  end


	def get_conversation_messages(page, customer, merchant=nil)
		convs_refs = self.conversation_refs.paginate(page: page, per_page: 10).includes(textable: [:images]).order(created_at: :desc)
		latest_messages = Array.new
		unread_ids = []  

		convs_refs.each do |cr| 
			unread_ids.push(cr.id) if cr.unread			
			latest_messages.push(message_hash(cr.textable, cr.id, customer, merchant))
    end
    [latest_messages, unread_ids.join(",")]
	end

	def message_hash(msg, ref_id, customer, merchant=nil)
    user = msg.user_id == self.merchant_id ? merchant : customer
		
    {
      id: msg.id,
      source: msg.user_id == self.merchant_id ? "merchant" : 'customer',
      profile_image: User.check_profile_picture(user),
      text: (msg.text) ? msg.text : '',
      ts_day_of_the_week: msg.created_at.strftime("%B") + " " + msg.created_at.strftime("%d").to_i.ordinalize,
      ts_time: msg.created_at.strftime('%l:%M %P'),
      unread: msg.unread,
      images: msg.images.map { |i| { ref: ref_id, url: i.avatar.url } },           # return small version here??
      msg_type: msg.class.name
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

  # customer can be nil
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

end