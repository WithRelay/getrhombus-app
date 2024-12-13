# frozen_string_literal: true

class Message < ActiveRecord::Base
  # for conversation
  has_many :conversation_refs, as: :textable, dependent: :destroy
  has_many :conversations, through: :conversation_refs

  belongs_to :txn, foreign_key: :transaction_id, class_name: :Transaction
  belongs_to :hashtag

  # for image table relation
  has_many :image_refs, as: :imageable, dependent: :destroy
  has_many :images, through: :image_refs

  validates :message_id, uniqueness: true, allow_nil: true

  belongs_to :user

  # For sending and saving all outbound text messages
  def send_and_save_message(merchant, user, from, to, message, media_ary = [])
    # save message before sending
    user = user.try(:id)
    update_attributes(user_id: merchant.id, user_id_to: user, from: from, to: to, text: message)
    sms_price = merchant.sms_fee.outbound_sms
    number = merchant.numbers.find_by(number: from)

    # if merchant.rn_type.present?      # twilio
    if number.number_type.present? # twilio
      response = TextingService.send_sms(from, to, message, media_ary)
      if response.first
        response = response.second
        num_segments = response.num_segments.to_i
        price = media_ary.blank? ? sms_price : merchant.sms_fee.outbound_mms
        # merchant.deduct_from_account_balance(price * num_segments)
        update_attributes(status: response.status, message_id: response.sid, message_timestamp: response.date_updated,
                          message_price: response.price, error_code: response.error_code, error_text: response.error_message,
                          price_unit: response.price_unit, num_segments: num_segments, num_media: response.num_media, relay_price: price)
      else
        ExceptionNotifier.notify_exception(StandardError.new,
                                           data: { message: 'From send_and_save_message, unable to send message', from: from, to: to, text: message,
                                                   env: Rails.env, response: response })
        false
      end
    # elsif merchant.fn_subscriber_id.present?   #  fibernetics
    elsif number.fibernetics_subscriber_id.present? #  fibernetics
      response = TextingService.send_sms_fibernetics(from, to, message, number.fibernetics_subscriber_id)
      if response && response.code == 200 && response['response']['status'] == 'OK'
        num_segments = Message.num_of_segments(message)
        merchant.deduct_from_account_balance(sms_price * num_segments)
        update_attributes(status: 'OK', num_segments: num_segments, relay_price: sms_price)
      else
        ExceptionNotifier.notify_exception(StandardError.new,
                                           data: { message: 'From send_and_save_message, unable to send message', from: from, to: to, text: message,
                                                   env: Rails.env, response: response })
        false
      end
    else # nexmo
      response = TextingService.send_sms_nexmo(from, to, message, id)
      if response.first && response.second.code == 200 && response.second['messages'].first['status'] == '0'
        response = response.second
        num_segments = response['message-count'].to_i
        # merchant.deduct_from_account_balance(sms_price * num_segments)
        update_attributes(status: response['messages'].first['status'], num_segments: num_segments, relay_price: sms_price,
                          message_id: response['messages'].first['message-id'], error_text: response['error-text'],
                          message_price: response['messages'].first['message-price'])
      else
        ExceptionNotifier.notify_exception(StandardError.new,
                                           data: { message: 'From send_and_save_message, unable to send message', from: from, to: to, text: message,
                                                   env: Rails.env, response: response })
        false
      end
    end
  rescue Exception => e
    ExceptionNotifier.notify_exception(e,
                                       data: { message: 'From send_and_save_message, unable to send message', from: from, to: to, text: message,
                                               env: Rails.env })
    false
  end

  def self.num_of_segments(msg)
    (msg.bytesize / 140.to_f).ceil
  end

  def self.relay_tip1
    "Relay tips: We've improved your payment experience with Relay by replacing the $ sign with a + tag. You can now text +10 instead of $10 to make a payment to a local business or non-profit."
  end

  def self.relay_tip2
    'Relay tips: With the + tag, you can now place the amount anywhere in the message. Ex. "pizza & broccoli +8 yay!" instead of "$8 pizza & broccoli'
  end

  def self.api_send(msg = nil)
    msg = msg.present? ? msg : 'Trios number test'
    webhook_url: '<redacted_webhook_url>'
    body = { key: '', secret: '', to: '',
             body: msg }
    options = { body: body.to_json, headers: { 'Content-Type' => 'application/json' } }
    HTTParty.post(webhook_url, options)
  rescue StandardError => e
    ExceptionNotifier.notify_exception(e,
                                       data: { message: 'In post_message_for_api_user', env: Rails.env,
                                               options: options })
  end

  def self.api_send_local
    webhook_url: '<redacted_webhook_url>'
    body = { key: '', secret: '', to: '',
             body: 'Api send test' }
    options = { body: body.to_json, headers: { 'Content-Type' => 'application/json' } }
    HTTParty.post(webhook_url, options)
  rescue StandardError => e
    ExceptionNotifier.notify_exception(e, data: { message: 'In post_message_for_api_user local', options: options })
  end

  def x(id_ary = [])
    user_ids = id_ary.present? ? id_ary : [7732, 7889, 7890, 7891, 7892, 7893]

    user_ids.each do |u_id|
      csv_string = CSV.generate do |csv|
        csv << ['Phone Number', 'Response', 'Segment', 'Timestamp (ET)', 'ID']
        # count = 0
        List.where(user_id: u_id, segment: nil).each do |l|
          UserList.where(list_id: l.id, customer_contact_type: 'MerchantContact').each do |ul|
            mc = MerchantContact.find_by(id: ul.customer_contact_id, is_customer: 0)
            next unless mc

            messages = Message.where(from: mc.uid, user_id_to: u_id)
            messages.each do |m|
              csv << [m.from, m.text, l.name, m.created_at.strftime('%Y-%m-%d %H:%M:%S'), m.id]
              # count = count + 1
              # puts count
            end
          end
        end
      end

      attachment_hash = { attachments: [{ content: Base64.encode64(csv_string),
                                          name: 'file.csv',
                                          type: 'text/csv' }] }

      EmailingService.email_to_platform("See Attached for User ID #{u_id}", 'RMG Data', attachment_hash)
    end
  end

  #=begin
  def y
    ary = [
      # 15_195_130_265, # went through
      # 15_193_426_611 # did not go through
      # 15_193_426_622 # did not go through
      # 14_167_621_761 # did not go through
      # 14_167_625_693 # did not go through
      # 14_167_625_979,
      # 16_474_303_507 # went through
      # <redacted_phone_number> # did not go through
      # 16_474_777_422 # did not go though
      # 19_054_632_690 # Did not go though
      # 19_052_310_601

    ]

    # Number.where(number: ary, provider: 'nexmo').delete_all

    # nexmo
    count = 0
    Number.where(number: ary).each_with_index do |n, _i|
      # TextingService.release_number(n.number)
      r = TextingService.release_number_nexmo(n.number, 'CA')
      puts r.inspect
      sleep 1
      n.destroy
      count += 1
      puts n.inspect, count, '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'
    end
    # ary.each_with_index { |n, i| TextingService.release_number_nexmo(n, 'CA'); puts i; }
    # ary.each_with_index { |n, i| TextingService.release_number_nexmo(n[0], n[1]); puts i; }
    # Twilio
    # ary.each_with_index { |n, i| TextingService.release_number(n); puts i; }
  end

  def yo1
    # emails = %w(<redacted_email> <redacted_email>)
    # 5239 numbers
    emails = ['<redacted_email>']

    emails.each do |e|
      u = User.find_by(email: e.downcase)
      next unless u

      count = 0

      Number.where(user_id: u.id, provider: 'nexmo').where('id < 38520').each_with_index do |n, _i|
        # Number.where(user_id: u.id, provider: 'twilio').each_with_index do |n, i|
        # TextingService.release_number(n)
        r = TextingService.release_number_nexmo(n.number, 'CA')
        puts r.inspect
        sleep 1
        n.destroy
        count += 1
        puts n.number.inspect, count, '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'
      end
    end
  end

  def yo2
    # emails = %w(<redacted_email> <redacted_email>)
    # 651 numbers
    emails = %w[
      <redacted_email>
    ]

    # u = User.where(email: emails.map(&:downcase)).pluck(:id)
    # puts Number.where(user_id: u).pluck(:provider).count

    count = 0
    emails.each do |e|
      u = User.find_by(email: e.downcase)
      next unless u

      Number.where(user_id: u.id).each do |n|
        if n.provider == 'nexmo'
          r = TextingService.release_number_nexmo(n.number, 'CA')
          puts r.inspect
          n.destroy
          sleep 1
        elsif n.provider == 'twilio'
          r = TextingService.release_number(n.number)
          puts r.inspect
          n.destroy if r
        end
        count += 1
        puts n.number.inspect, count, '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'
      end
    end
  end

  def q
    ary = []
    ary = Number.where(user_id: 39, provider: 'nexmo') # .order(id: :desc)#.limit(40)

    # nexmo
    ary.each_with_index do |n, i|
      TextingService.release_number_nexmo(n.number, 'CA')
      puts i
    end
    # ary.each_with_index { |n, i| TextingService.release_number_nexmo(n[0], n[1]); puts i; }
    # Twilio
    # ary.each_with_index { |n, i| TextingService.release_number(n); puts i; }
  end

  def z
    emails = %w[
      <redacted_email>
    ] # <redacted_email> <redacted_email> <redacted_email> <redacted_email>)

    puts 14_184_783_418
    emails.each do |e|
      u = User.find_by(email: e.downcase)
      next unless u

      Number.where('id > 32227').where(user_id: u.id, provider: 'nexmo').pluck(:number).each_with_index do |n, i|
        TextingService.update_nexmo_number('CA', n, 'tel', 14_373_703_562)
        puts i
      end
    end

    # ary.each_with_index { |n, i| TextingService.update_nexmo_number('CA', n, 'tel', <redacted_phone_number>); puts i; }
    # ary.each_with_index { |n, i| TextingService.update_nexmo_number("CA", n, 'tel', "<redacted_phone_number>"); puts i; }
  end

  def zz
    # 29544
    emails = [13_912]

    emails.each do |e|
      u = User.find_by(id: e)
      next unless u

      Number.where('id > 32168').where(user_id: u.id,
                                       provider: 'nexmo').pluck(:number).each_with_index do |n, i|
        TextingService.update_nexmo_number('CA', n, 'tel', 14_184_783_418)
        puts i
      end
    end

    # ary.each_with_index { |n, i| TextingService.update_nexmo_number('CA', n, 'tel', <redacted_phone_number>); puts i; }
    # ary.each_with_index { |n, i| TextingService.update_nexmo_number("CA", n, 'tel', "<redacted_phone_number>"); puts i; }
  end

  # 210950, 210948, 210949, 210929, 210961, 210962, 210964, 210966

  def z1
    emails = %w[
      <redacted_email>
      <redacted_email>
    ]
    emails.each do |e|
      u = User.find_by(email: e.downcase)
      next unless u

      Number.where(user_id: u.id, provider: 'nexmo').pluck(:number).each_with_index do |n, i|
        puts n.inspect
        TextingService.update_nexmo_number('CA', n, 'tel', 12_048_002_135)
        puts i
      end
    end

    # ary.each_with_index { |n, i| TextingService.update_nexmo_number('CA', n, 'tel', <redacted_phone_number>); puts i; }
    # ary.each_with_index { |n, i| TextingService.update_nexmo_number("CA", n, 'tel', "<redacted_phone_number>"); puts i; }
  end

  def r
    user = User.find_by(id: 124_064)
    ary = ['<redacted_phone_number>']

    ary.each_with_index do |n, _i|
      n = n.to_s
      next unless user

      res = TextingService.buy_number_nexmo('US', n)

      if res
        # default = i == 0 ? 1 : 0
        default = 0
        fn = '(' + n[1..3] + ') ' + n[4..6] + '-' + n[7..10]
        user.numbers.create(user_id: user.id, number: n, friendly_name: fn, country: 'CA', default: default,
                            provider: 'nexmo', price: '210')
        # TextingService.update_nexmo_number('CA', n, 'tel', '<redacted_phone_number>')
      else
        puts "CANT BUY #{n}"
      end
    end
  end

  # <redacted_phone_number> through <redacted_phone_number>
  # 16_476_703_711
  def p
    ary = [
    ]

    user = User.find_by(id: 210_928)
    ary.each_with_index do |n, _i|
      n = n.to_s
      # default = i == 0 ? 1 : 0
      default = 0
      fn = '(' + n[1..3] + ') ' + n[4..6] + '-' + n[7..10]
      user.numbers.create(user_id: user.id, number: n, friendly_name: fn, country: 'CA', default: default,
                          provider: 'nexmo', price: '210')
    end
  end
  #=end

  def qwe
    # my numbers
    a = [
    ]

    x = []
    b.each_with_index do |n, _i|
      # puts 1
      if a.exclude? n
        puts n.to_s + ','
        x << n
      end
    end
    puts x.length
  end

  def qawb
    ary = []

    # user = nil
    user = User.find_by(email: '<redacted_email>')

    ary.each_with_index do |n, i|
      n = n.to_s
      # user = User.find_by(email: "bcstrong#{n[1..3]}@imkgp.com")
      next unless user && Number.where(user_id: user.id).count < 21

      res = TextingService.buy_number_nexmo('CA', n)

      if res
        default = i == 0 ? 1 : 0
        # default = 0
        fn = '(' + n[1..3] + ') ' + n[4..6] + '-' + n[7..10]
        user.numbers.create(user_id: user.id, number: n, friendly_name: fn, country: 'CA', default: default,
                            provider: 'nexmo', price: '210')
        # TextingService.update_nexmo_number('CA', n, 'tel', '<redacted_phone_number>')
      else
        puts "CANT BUY #{n}"
      end
    end
  end

  def qawc
    ary = [


    ]

    # user = nil
    user = User.find_by(email: ''.downcase)

    ary.each_with_index do |n, _i|
      n = n.to_s
      # user = User.find_by(email: "ontariostrong#{n[1..3]}<redacted_email>")

      next unless user

      res = TextingService.buy_number_nexmo('CA', n)

      if res
        # default = i == 0 ? 1 : 0
        default = 0
        fn = '(' + n[1..3] + ') ' + n[4..6] + '-' + n[7..10]
        user.numbers.create(user_id: user.id, number: n, friendly_name: fn, country: 'CA', default: default,
                            provider: 'nexmo', price: '210')
        TextingService.update_nexmo_number('CA', n, 'tel', '<redacted_phone_number>')
      else
        puts "CANT BUY #{n}"
      end
    end
  end

  def rew
    user_id = 51_630
    phone_numbers = Message.where(user_id_to: user_id).pluck(:from)
    mcids = MerchantContact.where(merchant_id: user_id, uid: phone_numbers).pluck(:id)
    s = UserList.where(customer_contact_id: mcids, customer_contact_type: 'MerchantContact').where('created_at > ?',
                                                                                                   Time.now - 10.days)

    puts phone_numbers.length.inspect
    puts mcids.length.inspect
    puts s.length.inspect
    # s.delete_all
  end

  def wq
    emails = %w[<redacted_email> <redacted_email> <redacted_email> <redacted_email>
                <redacted_email> <redacted_email>]
    rules = Rule.where(user_id: 48_784).where('response like ?', '%first and last name?%')
    puts "Rules count #{rules.size}"
    rules.each do |r|
      emails.each do |e|
        puts "Selecting account #{e}"
        u = User.find_by(email: e.downcase)
        next unless u

        puts "Processing account #{u.email}"
        new_rule = r.dup
        new_rule.user_id = u.id
        new_rule.save
      end
    end
  end

  def wq1
    emails = %w[<redacted_email>]
    rules = Rule.where(user_id: 28_681) # .where("response like ?", '%first and last name?%')
    puts "Rules count #{rules.size}"
    rules.each do |r|
      emails.each do |e|
        puts "Selecting account #{e}"
        u = User.find_by(email: e.downcase)
        next unless u

        puts "Processing account #{u.email}"
        new_rule = r.dup
        new_rule.user_id = u.id
        new_rule.save
      end
    end
  end

  def wq2
    CSV::Converters[:blank_to_nil] = lambda do |field|
      field && field.blank? ? nil : field
    end

    emails = %w[
      <redacted_email>
      <redacted_email>
      <redacted_email>
      <redacted_email>
      <redacted_email>
      <redacted_email>
      <redacted_email>
      <redacted_email>
      <redacted_email>
      <redacted_email>
      <redacted_email>
      <redacted_email>
      <redacted_email>
      <redacted_email>
      <redacted_email>
      <redacted_email>
      <redacted_email>
      <redacted_email>
      <redacted_email>
      <redacted_email>
      <redacted_email>
    ].map(&:downcase)

    user_ids = User.where(email: emails).pluck(:id)
    # Rule.create(user_id: 123_807, text: HERE, rule_type: 'contains_text', response: 'Thanks for your time. Stay well.')
    file_data = CSV.read('/home/taiwo/Downloads/Rules to add to funnel accounts - Sep 2.csv', encoding: 'ISO-8859-1',
                                                                                              headers: true, skip_blanks: true, header_converters: :symbol, converters: %i[all blank_to_nil], skip_lines: /^(?:[,:;]\s*)+$/)

    data = []
    file_data.each do |row|
      row = row.to_hash
      user_ids.each do |uid|
        data << { user_id: uid, text: row[:text], rule_type: row[:rule_type], response: row[:response] }
      end
      if data.length == 5000
        Rule.import data, validate: false
        data.clear
      end
    end
    Rule.import(data, validate: false) if data.present?
  end

  def wq3
    rules = Rule.where(user_id: 220_253).pluck(:text, :rule_type, :response, :message_length)

    %w[
      <redacted_email>
    ].each do |e|
      user = User.find_by(email: e.downcase)

      data = []
      rules.each do |r|
        data << { user_id: user.id, text: r.first, rule_type: r.second, response: r.third, message_length: r.fourth }
        if data.length == 10_000
          Rule.import data, validate: false
          data.clear
        end
      end
      Rule.import(data, validate: false) if data.present?
    end
  end

  def sss
    r = [
      'no.',
      'N',
      'sorry no',
      'never',
      'fuck no',
      'hell freez',
      'Never Conservative',
      'Absolutely no',
      'Hell No',
      'no!',
      'agree',
      'disagree'
    ]

    Rule.where(text: r, rule_type: 'contains_only_text', user_id: 123_807)
  end

  def run_rules
    message_text = text.downcase.strip
    return if message_text.blank?

    @merchant = User.find_by(id: user_id_to)
    rules = @merchant.rules.order(id: :asc).pluck(:text, :response, :rule_type, :message_length, :id)
    return if rules.blank?

    rules.each do |rule|
      rule_text = rule.first.downcase.strip
      response = rule.second

      case rule.third
      when 'starts_with_text'
        if message_text.starts_with?(rule_text)
          puts 1
          break
        end
      when 'starts_with_text_and_length_is_less_than_x'
        if message_text.starts_with?(rule_text) && message_text.size < (rule.fourth + 1)
          puts 2
          break
        end
      when 'contains_text'
        if message_text.include?(rule_text)
          puts rule_text
          puts message_text
          puts @merchant.id
          puts rule.inspect
          puts 3
          break
        end
      when 'contains_only_text'
        if message_text == rule_text
          puts 4
          break
        end
      when 'contains_text_and_length_is_less_than_x'
        if message_text.include?(rule_text) && message_text.size < (rule.fourth + 1)
          puts 5
          break
        end
      end
    end
  end

  def move_numbers
    [
      { from: ['<redacted_email>', '<redacted_email>'],
        to: '<redacted_email>' },
      { from: ['<redacted_email>'], to: '<redacted_email>' },
      { from: ['<redacted_email>'], to: '<redacted_email>' },
      { from: ['<redacted_email>'], to: '<redacted_email>' },
      { from: ['<redacted_email>', '<redacted_email>'],
        to: '<redacted_email>' }
    ].each do |arr|
      to = User.find_by_email(arr[:to])
      next if to.blank?

      # puts to.email, Number.where(user_id: to.id).count
      puts "to ---->>>>>>>>>>>>>>>>>>>> #{to.id}"

      arr[:from].each do |email|
        from = User.find_by_email(email)
        next if from.blank?

        puts "from #{from.email}"
        # puts from.email, Number.where(user_id: from.id).count
        # Number.where(user_id: from.id).update_all(user_id: to.id)
      end
    end
  end

  def delete_rule
    arr = %w[
      <redacted_email>
      <redacted_email>
      <redacted_email>
      <redacted_email>
      <redacted_email>
      <redacted_email>
      <redacted_email>
      <redacted_email>
      <redacted_email>
    ]

    user_ids = User.where(email: arr).pluck(:id)
    Rule.where(user_id: user_ids).delete_all
  end
end
