class Conversation < ActiveRecord::Base

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
####convs = where(merchant_id: merchant_id, message_resolution_id: nil).paginate(page: page, per_page: 25)
  	convs = where(merchant_id: merchant_id).paginate(page: page, per_page: 25)
  	latest_conv = Array.new

  	convs.each do |conv|
  		if conv.uid_type == "user"
  			full_name = User.find_by(conv.uid).card_name
  		else
  			# does fb at least give us some info?
  			full_name = (conv.uid_type == 'fb_page') ? "messenger user" : conv.uid
  		end

  		latest_conv.push(conv.conversation_hash)
     # return latest_conv
  	end

  	latest_conv

=begin
    # name is now thrugh person
    users = Message.select('`users`.`id`, `users`.`first_name`, `users`.`last_name`, `users`.`email`, `messages`.`from`')
                   .joins('LEFT JOIN `users` ON (`users`.`id` = `messages`.`user_id`)')
                   .where('(`messages`.`user_id_to` = ? AND `messages`.`created_at` >= ?) OR (`messages`.`user_id_to` = ? AND `messages`.`unread` = ?)', merchant_id, Time.current - num_days.days, merchant_id, true)
                   .group('`messages`.`from`')
    latest_active = Array.new
    users.each do |user|
      last_message = user.id.blank? ? Message.select('text, created_at').where('`from` = ? AND `user_id_to` = ?', user.from, merchant_id).order('created_at DESC').limit(1).first : Message.select('text, created_at').where('user_id = ? AND user_id_to = ?', user.id, merchant_id).order('created_at DESC').limit(1).first
      latest_active.push({
        :user_number => user.from,
        :first_name => user.first_name.blank? ? user.from : user.first_name,
        :last_name => user.last_name.blank? ? '' : user.last_name,
        :email => user.email.blank? ? '' : user.email,
        :profile_image => ActionController::Base.helpers.asset_path('user_icon_50x50.png'),
        :last_message => last_message.blank? ? '' : last_message.text,
        :last_message_ts => last_message.blank? ? 0 : last_message.created_at.to_i,
        :unread_count =>  user.id.blank? ? Message.where('`from` = ? AND `user_id_to` = ? AND `unread` = ?', user.from, merchant_id, true).count : Message.where('user_id = ? AND user_id_to = ? AND unread = ?', user.id, merchant_id, true).count
      })
    end
    latest_active
=end
	end

  def conversation_hash(user = nil)
    last_message = ConversationRef.where(conversation_id: self.id).last
    last_message = (last_message) ? last_message.textable : nil

    if self.uid_type == "user"
      full_name = (user) ? user.card_name : User.find_by(self.uid).card_name
    else
      # does fb at least give us some info?
      full_name = (self.uid_type == 'fb_page') ? "messenger user" : self.uid
    end

    {
      id: self.id,
      uid_type: self.uid_type,
      uid: self.uid,
      full_name: full_name || "",
      profile_image: ActionController::Base.helpers.asset_path('user_icon_50x50.png'),
      last_message: last_message.blank? ? '' : last_message.text,
      last_message_ts: last_message.blank? ? 0 : last_message.created_at.to_i,
      last_message_type: last_message.class.name,
      unread_count: ConversationRef.where(conversation_id: self.id, unread: true).count
    }
  end


	def get_conversation_messages(page)
		convs_refs = self.conversation_refs.paginate(page: page, per_page: 7).includes(textable: [:images])
		latest_messages = Array.new
		unread_ids = []

		convs_refs.each do |cf|
			unread_ids.push(cf.id) if cf.unread
			latest_messages.push(message_hash(cf.textable))
    end
    [latest_messages, unread_ids.join(",")]
	end

	def message_hash(msg)
		# Used for profile image...This should change if merchant can talk to merchant? or change how we determine profile image
		user_level = msg.user_id == self.merchant_id ? 1 : 0

		{
      id: msg.id,
      source: msg.user_id == self.merchant_id ? "merchant" : 'user',
      profile_image: (user_level == 0) ? ActionController::Base.helpers.asset_path('user_icon_50x50.png') : ActionController::Base.helpers.asset_path('rhombus_icon_50x50.png'),
      text: (msg.text) ? msg.text : nil,
      ts_day_of_the_week: msg.created_at.strftime('%A'),
      ts_time: msg.created_at.strftime('%l:%M %P'),
      unread: msg.unread,
      image_urls: "https://i0.wp.com/www.asphaltandrubber.com/wp-content/uploads/2012/11/2013-KTM-390-Duke-high-resolution-02.jpg",#msg.images.map { |i| i.avatar.url },           # return small version here??
      msg_type: msg.class.name
  	}
	end

    # Returns hash with the last "num_messages" messages that the given user has sent to the given merchant
  def self.get_user_messages_by_merchant(user_number, merchant_id, num_messages)
    messages = Message.includes(:images)
                                        .select('`messages`.`user_id`,`messages`.`text`,`messages`.`unread`,`messages`.`created_at`,`users`.`user_level`')#, `messages`.`image_id`')
                        .joins('LEFT JOIN `users` ON (`users`.`id` = `messages`.`user_id`)')
                        .where('(`messages`.`from` = ? AND `messages`.`user_id_to` = ?) OR (`messages`.`user_id` = ? AND `messages`.`to` = ?)', user_number, merchant_id, merchant_id, user_number)
                        .order('`messages`.`created_at` DESC').limit(num_messages)
    latest_messages = Array.new
    messages.reverse.each do |message|
      latest_messages.push({
        :user_number => message.user_id,
        :user_level => message.user_level.blank? ? 0 : message.user_level,
        :profile_image => (message.user_level.blank? || (message.user_level == 0)) ? ActionController::Base.helpers.asset_path('user_icon_50x50.png') : ActionController::Base.helpers.asset_path('rhombus_icon_50x50.png'),
        :text => (message.text) ? message.text : nil,
        :ts_day_of_the_week => message.created_at.strftime('%A'),
        :ts_time => message.created_at.strftime('%l:%M %P'),
        :unread => true#message.unread,
        # return small version here??
        #:image_url => message.image_id? ? message.image.avatar.url : nil
      })
    end
    latest_messages
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

  # user can be nil
  # uid can be user id, phone number or messenger id
  def send_message(team, user, msg, channel, unread, uid = nil, uid_type = nil, media = [])
		from = (channel == "FbMessage") ? "get messenger cred" : team.rhombus_number
    to = (channel == "FbMessage") ? 'get messenger cred' : user.phone_number if user.present?

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

		if msg_instance.send_and_save_message(team, user, from, to, msg, unread, media)
			find_or_create_conversation_for_message(team.id, uid_type, uid, msg_instance, unread)
			message_hash(msg_instance)
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
    conv.conversation_refs.create(textable: msg, unread: unread)
  end

end
