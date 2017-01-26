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
  		last_message = ConversationRef.where(conversation_id: conv.id).last.textable

  		if conv.uid_type == "user"
  			full_name = User.find_by(conv.uid).card_name
  		else 
  			# does fb at least give us some info?
  			full_name = (conv.uid_type == 'fb_page') ? "messenger user" : conv.uid
  		end

  		latest_conv.push({
        user_id: conv.uid,
        uid_type: conv.uid_type,
        conversation_id: conv.id,
        full_name: full_name || "",
        profile_image: ActionController::Base.helpers.asset_path('user_icon_50x50.png'),
        last_message: last_message.blank? ? '' : last_message.text,
        last_message_ts: last_message.blank? ? 0 : last_message.created_at.to_i,
        unread_count: ConversationRef.where(conversation_id: 1, unread: true).count
      })
  	end
  	puts latest_conv.to_json
  	latest_conv

  	#where(message_resolution_id: nil, merchant_id: merchant_id).paginate(page: page, per_page: 25)

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


	def self.get_conversation_messages(conv_id, page)
		convs_refs = ConversationRef.includes(:textable).where(conversation_id: conv_id).paginate(page: page, per_page: 25)
		latest_messages = Array.new

		  			full_name = User.find_by(conv.uid).card_name
		  			  		last_message = ConversationRef.where(conversation_id: conv.id).last.textable


		
		convs_refs.each do |cf|
			msg = cf.textable
      latest_messages.push({
        :user_number => message.user_id,
        :user_level => message.user_level.blank? ? 0 : message.user_level,
        :profile_image => (message.user_level.blank? || (message.user_level == 0)) ? ActionController::Base.helpers.asset_path('user_icon_50x50.png') : ActionController::Base.helpers.asset_path('rhombus_icon_50x50.png'),
        text: (msg.text) ? msg.text : nil,
        ts_day_of_the_week: msg.created_at.strftime('%A'),
        ts_time: msg.created_at.strftime('%l:%M %P'),
        unread: msg.unread,
        # return small version here??
        #:image_url => message.image_id? ? message.image.avatar.url : nil
      })
    end
    latest_messages
		#x.to_json
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
        :unread => message.unread,
        # return small version here??
        #:image_url => message.image_id? ? message.image.avatar.url : nil
      })
    end
    latest_messages
  end


end