# frozen_string_literal: true

class Conversation < ActiveRecord::Base
  include PrettyDate

  belongs_to :merchant, class_name: 'User'
  has_many :conversation_refs, dependent: :destroy
  has_many :conversation_resolutions, dependent: :destroy
  has_many :fb_messages, through: :conversation_refs, source: :textable, source_type: 'FbMessage', dependent: :destroy
  has_many :messages, through: :conversation_refs, source: :textable, source_type: 'Message', dependent: :destroy

  def user # the user texting this merchant
    User.find_by(id: uid)
  end

  def self.get_open_conversations_count(merchant_id)
    where(merchant_id: merchant_id, is_resolved: false).count
  end

  # Returns hash with users who sent a message to the given merchant in the last "num_days" days
  def self.get_open_conversations(merchant_id, page)
    convs = where(merchant_id: merchant_id, is_resolved: false).paginate(page: page, per_page: 10).order(updated_at: :desc, id: :desc)
    convs.map(&:conversation_hash)

    # this is for test.
    # x = convs.map { |conv| conv.conversation_hash }
    # x.first[:profile_image] = { type: 'image', value: 'http://lorempixel.com/400/200/' } if x.present?
    # x
  end

  def conversation_hash
    last_message = ConversationRef.where(conversation_id: id).last

    if last_message.present?
      last_message = last_message.textable
      if last_message.present? && last_message.text.blank? && last_message.images.exists?
        last_message.text = 'image attached'
      end
    end

    mc = if uid_type == 'user'
           MerchantCustomer.find_by(merchant_id: merchant_id, customer_id: uid)
         # has_messenger = self.user.try(:get_customer_page_specific_id, self.merchant.get_page_access_token) && true
         else
           MerchantContact.find_by(merchant_id: merchant_id, uid: uid, uid_type: uid_type)
           # has_messenger = mc.try(:page_specific_id_valid?)
         end

    {
      id: id,
      uid: uid,
      uid_type: uid_type,
      # has_messenger: has_messenger,
      mc_id: mc.try(:id).try(:to_s),
      mc_type: mc ? mc.class.name : nil,
      profile_image: User.check_profile_picture(user),
      last_message: last_message ? last_message.text : '',
      last_message_ts: last_message.try(:created_at).to_i,
      last_message_type: last_message ? last_message.class.name : nil, # channel
      full_name: User.get_conversation_display_name(uid, uid_type),
      ago: last_message ? time_in_relative_form(last_message.created_at, 'short_format') : '',
      unread_count: ConversationRef.where(conversation_id: id, unread: true, source: ConversationRef.sources[:customer]).count
    }
  end

  def self.get_conversation_messages(conv, conv_ref_id)
    where_str = conv_ref_id.present? ? 'conversation_refs.id < ?' : ''
    convs_refs = conv.conversation_refs.where(where_str, conv_ref_id).includes(textable: [:images]).order(created_at: :desc, id: :desc).limit(10)
    convs_refs.map { |cr| message_hash(conv, cr.textable, cr) }
  end

  def self.message_hash(conv, msg, conv_ref)
    {
      id: msg.id,
      conv_ref_id: conv_ref.id,
      source: msg.user_id == conv.merchant_id ? 'merchant' : 'customer', # or conv_ref.source
      text: msg.text || '',
      ts_day_of_the_week: msg.created_at.strftime('%B') + ' ' + msg.created_at.strftime('%d').to_i.ordinalize,
      ts_time: msg.created_at.strftime('%l:%M %P'),
      ts: msg.created_at.to_i,
      ago: Conversation.new.time_in_relative_form(msg.created_at, 'short_format'),
      unread: conv_ref.unread,
      images: msg.images.map { |i| { id: i.id, url: i.avatar.url } },
      channel: msg.class.name
    }
  end

  # uid can be user id, phone number or messenger id
  def self.send_message(conv, team, msg, channel, source, media = [], from = nil)
    # from = (channel == "FbMessage") ? team.get_page_access_token : team.rhombus_number
    from = channel == 'FbMessage' ? team.get_page_access_token : conv.get_from_number(from)

    if conv.uid_type == 'user'
      customer = conv.user
      # supports merchant dashboard chat
      to = channel == 'FbMessage' ? customer.get_customer_page_specific_id(from.try(:page_access_token)) : customer.phone_number
      # to = (channel == "FbMessage") ? customer.get_customer_page_specific_id(from) : (customer.is_merchant? ? customer.rhombus_number : customer.phone_number)
    else
      to = conv.uid
      if channel == 'FbMessage'
        mc = MerchantContact.find_by(merchant_id: conv.merchant_id, uid: conv.uid, uid_type: conv.uid_type)
        to = nil unless mc.page_specific_id_valid?(team)
      end
    end

    return false unless from.present? && to.present?

    msg_instance = channel.constantize.new

    # Relate message to files
    media_urls = []
    if media.present?
      media_ids = []
      media.each do |m|
        media_ids.push(m.id)
        media_urls.push(m.avatar.url)
      end
      msg_instance.image_ids = media_ids
    end
    if msg_instance.send_and_save_message(team, customer, from, to, msg, media_urls)
      re = find_or_create_conversation_for_message(team.id, conv.uid_type, conv.uid, msg_instance, false, source)
      msg_hash = message_hash(re[0], msg_instance, re[1])
      # Rails.logger.debug "DEBUG: we got this far at lesat success"
      [msg_hash, msg_instance, re.second] # message hash, instance and message conv ref are needed
    else
      # Rails.logger.debug "DEBUG: we got this far at lesat fail"
      false
    end
  rescue StandardError => e
    ExceptionNotifier.notify_exception(e, data: { message: 'In conversations.rb send_message', env: Rails.env, conv: conv, team: team, msg: msg, to: to })
    false
  end

  #   def get_from_number
  #     team = self.merchant
  #     last_message = ConversationRef.includes(:textable).where(conversation_id: self.id).try(:textable)
  #     return team.rhombus_number unless last_message  # Ex. Merchant texting customer for the first time
  #     from = last_message.user_id == team.id ? last_message.from : last_message.to     # inbound/outbound logic
  #     Number.unscoped.exists?(user_id: team.id, number: from) ? from : team.rhombus_number    # check that merchant still owns the number else use default
  #   end

  def get_from_number(from_to_use)
    team = merchant
    last_message = ConversationRef.includes(:textable).where(conversation_id: id).last.try(:textable) # maybe do a direct messages search here???????????????
    unless last_message
      return (from_to_use || team.rhombus_number)
    end # Ex. Merchant texting customer/contact for the first time

    from = last_message.user_id == team.id ? last_message.from : last_message.to # inbound/outbound logic
    Number.unscoped.exists?(user_id: team.id, number: from) ? from : (from_to_use || team.rhombus_number) # check that merchant still owns the number else use default
  end

  # When sending by platform on behalf of platform or merchant FOR automated (platform triggered), 3rd party app messages (Slack) and configured messages (Rules)
  # Excludes sending from dashboard and campaigns
  def self.find_or_create_conversation_for_message_and_send_publish(team, customer, uid_type, uid, msg_to_send, channel = 'Message', media = [], source = 'platform', from = nil)
    re = find_or_create_conversation(team.id, uid_type, uid)
    msg_ary = send_message(re, team, msg_to_send, channel, source, media, from)
    if msg_ary
      RealtimeStreamService.messages(re, msg_ary.third, customer, msg_ary.second)
      msg_ary.first[:id]
    else
      false
    end
  end

  # When sending by platform on behalf of platform or merchant FOR CAMPAIGNS ONLY
  # The main difference with method above is that it doesn't stream to dashboard. Streaming a 5000 recipient campaign to dashboard can make the conversations page really busy
  # Note Customer parameter not needed
  def self.find_or_create_conversation_for_message_and_send(team, uid_type, uid, msg_to_send, channel = 'Message', media = [], source = 'platform', from = nil)
    re = find_or_create_conversation(team.id, uid_type, uid)
    msg_ary = send_message(re, team, msg_to_send, channel, source, media, from)
    msg_ary ? msg_ary.first[:id] : false
  end

  # when receiving
  def self.find_or_create_conversation_for_message_and_publish(team, customer, uid_type, uid, msg_instance, unread)
    re = find_or_create_conversation_for_message(team.id, uid_type, uid, msg_instance, unread, 'customer')
    RealtimeStreamService.messages(re[0], re[1], customer, msg_instance)
  end

  # find or create conversation and attach new message
  def self.find_or_create_conversation_for_message(team_id, uid_type, uid, msg_instance, unread, source)
    conv = find_or_create_conversation(team_id, uid_type, uid)
    is_new_conv = !conv.conversation_refs.exists?
    conv_ref = conv.conversation_refs.create(textable: msg_instance, unread: unread, source: source)

    # Basically, customer, merchant and platform messages should change conversation status to open
    # Campaign should leave as is or close if it creates the convesation
    if ['campaign'].include?(source) && is_new_conv
      conv.update(is_resolved: true, updated_at: conv_ref.created_at)
    elsif %w[customer merchant platform].include?(source)
      conv.update(is_resolved: false, updated_at: conv_ref.created_at)
    end

    update_conversation_resolution(team_id, conv.id, conv_ref.id, source)
    [conv, conv_ref]
  end

  def self.update_conversation_resolution(team_id, conv_id, conv_ref_id, source)
    conv_res = ConversationResolution.where(conversation_id: conv_id, resolution: nil).last || ConversationResolution.new
    key = source == 'customer' ? :uid_conversation_ref_id : :merchant_conversation_ref_id
    conv_res.update_attributes(key => conv_ref_id, merchant_id: team_id, conversation_id: conv_id)
  end

  # find the conversation or create one
  def self.find_or_create_conversation(team_id, uid_type, uid)
    Conversation.includes(:merchant).find_or_create_by(merchant_id: team_id, uid_type: uid_type, uid: uid)
  end

  # get the total number of unread messages for a merchant on or after a date
  def self.get_merchant_todays_unread_count(merchant_id, date)
    find_by_sql(["select count(cr.id) as count from conversations c inner join conversation_refs cr
                  on c.id = cr.conversation_id where cr.unread = 1 and c.is_resolved is false
                  and c.merchant_id = ? and cr.created_at >= ? and source = #{ConversationRef.sources[:customer]}", merchant_id, date])
      .first.count
  end

  # get the last message from the last 5 conversations a merchant has had on or after a date
  def self.get_last_customer_msg_from_last5_convs_today(merchant_id, date)
    find_by_sql(["SELECT b.id as id, a.textable_id, b.uid, b.uid_type, a.created_at as created_at,
                  CASE WHEN a.textable_type = 'Message' THEN 'SMS' ELSE 'messenger' END as channel
                  FROM conversation_refs a
                  INNER JOIN (
                    SELECT e.id as id, max(c.id) as cr_id, e.uid as uid, e.uid_type as uid_type
                    FROM conversation_refs c
                    INNER JOIN (
                      SELECT id, uid, uid_type from conversations d
                      where d.merchant_id = ? and d.is_resolved is false
                      and d.updated_at >= ? order by d.updated_at desc, id desc limit 5
                      ) e ON e.id = c.conversation_id
                    where source = #{ConversationRef.sources[:customer]} GROUP BY c.conversation_id
                  ) b ON a.id = b.cr_id order by a.created_at desc, id desc", merchant_id, date])
  end

  def self.update_conv_contact_to_user(psid, customer)
    where(uid: psid, uid_type: 'fb_page').each do |c|
      c.uid_type = 'user'
      c.uid = customer.id
      RealtimeStreamService.update_conversation_properties(c.id, customer, c.merchant_id, "#{psid}-fb_page") if c.save
    end
  end

  def self.publish_test_conversation
    conversation = Conversation.first
    conv_ref = ConversationRef.first
    customer = User.find 22
    msg = Message.find 280
    RealtimeStreamService.messages(conversation, conv_ref, customer, msg)
  end
end
