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
        ExceptionNotifier.notify_exception(StandardError.new, data: { message: 'From send_and_save_message, unable to send message', from: from, to: to, text: message, env: Rails.env, response: response })
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
        ExceptionNotifier.notify_exception(StandardError.new, data: { message: 'From send_and_save_message, unable to send message', from: from, to: to, text: message, env: Rails.env, response: response })
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
        ExceptionNotifier.notify_exception(StandardError.new, data: { message: 'From send_and_save_message, unable to send message', from: from, to: to, text: message, env: Rails.env, response: response })
        false
      end
    end
  rescue Exception => e
    ExceptionNotifier.notify_exception(e, data: { message: 'From send_and_save_message, unable to send message', from: from, to: to, text: message, env: Rails.env })
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
    body = { key: 'wdJobH3wLOafkjPn3Yn5TQtt', secret: 'XyQjmW19Jf3cCNyesqEHmQtt', to: '<redacted_phone_number>',<redacted_phone_number>', body: msg }
    options = { body: body.to_json, headers: { 'Content-Type' => 'application/json' } }
    HTTParty.post(webhook_url, options)
  rescue StandardError => e
    ExceptionNotifier.notify_exception(e, data: { message: 'In post_message_for_api_user', env: Rails.env, options: options })
  end

  def self.api_send_local
    webhook_url: '<redacted_webhook_url>'
    body = { key: 'QBy6xmWxUkvCndzJmw1LcAtt', secret: '80O4jUQVdYSP3zrnPyYMMgtt', to: '<redacted_phone_number>',<redacted_phone_number>', body: 'Api send test' }
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

      Number.where(user_id: u.id, provider: 'nexmo').each_with_index do |n, _i|
        # Number.where(user_id: u.id, provider: 'twilio').each_with_index do |n, i|
        # TextingService.release_number(n)
        r = TextingService.release_number_nexmo(n.number, 'US')
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
      <redacted_email>
      <redacted_email>
      <redacted_email>
    ]

    # u = User.where(email: emails.map(&:downcase)).pluck(:id)
    # puts Number.where(user_id: u).pluck(:provider).count

    count = 0
    emails.each do |e|
      u = User.find_by(email: e.downcase)
      next unless u

      Number.where(user_id: u.id).each_with_index do |n, _i|
        # TextingService.release_number(n.number)
        r = TextingService.release_number_nexmo(n.number, 'CA')
        puts r.inspect
        sleep 1
        n.destroy
        count += 1
        puts n.number.inspect, count, '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'
      end
    end
  end

  def q
    ary = []
    ary = Number.where(user_id: 198_518, provider: 'nexmo') # .order(id: :desc)#.limit(40)

    # nexmo
    ary.each_with_index { |n, i| TextingService.release_number_nexmo(n.number, 'CA'); puts i; }
    # ary.each_with_index { |n, i| TextingService.release_number_nexmo(n[0], n[1]); puts i; }
    # Twilio
    # ary.each_with_index { |n, i| TextingService.release_number(n); puts i; }
  end

  def z
    emails = %w[
      <redacted_email>
      <redacted_email>
    ] # <redacted_email> <redacted_email> <redacted_email> <redacted_email>)

    emails.each do |e|
      u = User.find_by(email: e.downcase)
      if u
        Number.where(user_id: u.id, provider: 'nexmo').pluck(:number).each_with_index { |n, i| TextingService.update_nexmo_number('CA', n, 'tel', 14_038_000_656); puts i; }
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
      if u
        Number.where('id > 32168').where(user_id: u.id, provider: 'nexmo').pluck(:number).each_with_index { |n, i| TextingService.update_nexmo_number('CA', n, 'tel', 14_184_783_418); puts i; }
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
      <redacted_email>
      <redacted_email>
      <redacted_email>
      <redacted_email>
    ]
    emails.each do |e|
      u = User.find_by(email: e.downcase)
      if u
        Number.where(user_id: u.id, provider: 'nexmo').pluck(:number).each_with_index { |n, i| TextingService.update_nexmo_number('CA', n, 'tel', 14_038_000_656); puts i; }
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
        user.numbers.create(user_id: user.id, number: n, friendly_name: fn, country: 'CA', default: default, provider: 'nexmo', price: '210')
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
      16_476_703_702,
      16_476_703_703,
      16_476_703_704,
      16_476_703_705,
      16_476_703_706,
      16_476_703_707,
      16_476_703_708,
      16_476_703_709,
      16_476_703_710,
      16_476_703_711
    ]

    user = User.find_by(id: 210_928)
    ary.each_with_index do |n, _i|
      n = n.to_s
      # default = i == 0 ? 1 : 0
      default = 0
      fn = '(' + n[1..3] + ') ' + n[4..6] + '-' + n[7..10]
      user.numbers.create(user_id: user.id, number: n, friendly_name: fn, country: 'CA', default: default, provider: 'nexmo', price: '210')
    end
  end
  #=end

  def qwe
    # my numbers
    a = [
      13_062_051_308,
      13_062_051_628,
      13_062_051_792,
      13_062_051_793,
      13_062_051_809,
      13_062_051_824,
      13_062_051_825,
      13_062_051_826,
      13_062_051_828,
      13_062_051_829,
      13_062_051_854,
      13_062_051_861,
      13_062_051_899,
      13_062_051_948,
      13_062_052_029,
      13_062_052_082,
      13_062_052_101,
      13_062_052_119,
      13_062_052_132,
      13_062_052_189,
      13_062_052_206,
      13_062_052_209,
      13_062_052_234,
      13_062_052_347,
      13_062_052_396,
      13_062_052_404,
      13_062_052_416,
      13_062_052_439,
      13_062_052_452,
      13_062_052_464,
      13_062_052_489,
      13_062_052_605,
      13_062_052_606,
      13_062_052_607,
      13_062_052_608,
      13_062_052_793,
      13_062_052_794,
      13_062_052_795,
      13_062_058_047,
      13_062_058_058,
      13_062_058_103,
      13_062_058_143,
      13_062_058_145,
      13_062_058_147,
      13_062_058_148,
      13_062_058_153,
      13_062_058_158,
      13_062_058_375,
      13_062_058_620,
      13_062_058_665,
      13_063_740_498,
      13_064_000_031,
      13_065_001_378,
      13_065_006_634,
      13_065_006_635,
      13_065_006_640,
      13_065_006_648,
      13_065_006_730,
      13_066_673_945,
      13_066_674_029,
      13_066_680_796,
      13_066_837_024,
      13_066_837_041,
      13_066_837_046,
      13_066_837_047,
      13_066_839_458,
      13_066_839_534,
      13_066_839_536,
      13_066_839_537,
      13_066_839_540,
      13_066_839_541,
      13_066_839_547,
      13_066_839_548,
      13_066_839_549,
      13_066_839_551,
      13_066_839_552,
      13_066_839_554,
      13_066_839_555,
      13_066_839_556,
      13_066_839_563,
      13_066_839_566,
      13_066_839_568,
      13_066_839_571,
      13_066_839_572,
      13_066_839_573,
      13_066_839_574,
      13_066_839_576,
      13_066_839_577,
      13_066_839_578,
      13_066_839_580,
      13_066_839_581,
      13_066_839_598,
      13_066_839_607,
      13_066_839_608,
      13_066_839_609,
      13_066_839_610,
      13_066_839_613,
      13_066_839_616,
      13_066_839_618,
      13_066_839_619,
      13_062_051_285,
      13_062_051_293,
      13_062_051_294,
      13_062_051_298,
      13_062_051_328,
      13_062_051_337,
      13_062_051_356,
      13_062_051_425,
      13_062_051_452,
      13_062_051_521,
      13_062_051_853,
      13_062_051_892,
      13_062_051_924,
      13_062_051_949,
      13_062_051_957,
      13_062_051_963,
      13_062_051_977,
      13_062_052_036,
      13_062_052_081,
      13_062_052_097,
      13_062_052_103,
      13_062_052_124,
      13_062_052_186,
      13_062_052_239,
      13_062_052_247,
      13_062_052_496,
      13_062_058_624,
      13_066_673_958,
      13_066_674_025,
      13_069_861_620,
      13_069_861_621,
      13_069_861_623,
      13_069_861_624,
      13_069_861_625,
      13_069_861_626,
      13_069_861_627,
      13_069_861_628,
      13_069_861_629,
      13_069_861_631,
      13_069_861_632,
      13_069_861_633,
      13_069_861_635,
      13_069_861_636,
      13_069_861_637,
      13_069_861_638,
      13_069_861_639,
      13_069_861_640,
      13_069_861_641,
      13_069_861_642,
      13_069_861_644,
      13_069_867_003,
      13_069_867_004,
      13_069_867_005,
      13_069_867_008,
      13_069_867_009,
      13_069_867_010,
      13_069_867_011,
      13_069_867_012,
      13_069_867_013,
      13_069_867_015,
      13_069_867_016,
      13_069_867_017,
      13_069_867_018,
      13_069_867_019,
      13_069_867_020,
      13_069_867_021,
      13_069_867_022,
      13_069_867_023,
      13_069_867_024,
      13_069_867_025,
      13_069_867_026,
      13_069_867_027,
      13_069_867_028,
      13_069_868_819,
      13_069_868_820,
      13_069_868_821,
      13_069_868_824,
      13_069_868_825,
      13_069_868_826,
      13_069_868_827,
      13_069_868_828,
      13_069_868_829,
      13_069_868_830,
      13_069_868_831,
      13_069_868_832,
      13_069_868_834,
      13_069_868_835,
      13_069_868_836,
      13_069_868_837,
      13_069_868_838,
      13_069_931_436,
      13_062_052_398,
      13_062_053_973,
      13_062_054_326,
      13_062_054_453,
      13_062_054_815,
      13_062_054_934,
      13_062_055_096,
      13_062_055_097,
      13_062_055_103,
      13_062_055_105,
      13_062_055_109,
      13_062_055_197,
      13_062_055_202,
      13_062_055_625,
      13_062_055_626,
      13_062_055_898,
      13_062_056_289,
      13_062_056_290,
      13_062_056_292,
      13_062_058_057,
      13_062_058_099,
      13_062_058_101,
      13_062_058_140,
      13_062_058_142,
      13_062_058_163,
      13_062_058_169,
      13_062_058_622,
      13_062_058_668,
      13_062_058_669,
      13_062_058_799,
      13_062_058_801,
      13_062_058_803,
      13_062_058_806,
      13_062_058_811,
      13_062_058_816,
      13_062_058_820,
      13_062_058_821,
      13_062_058_823,
      13_062_058_825,
      13_062_058_826,
      13_062_058_829,
      13_062_058_857,
      13_062_058_865,
      13_062_058_902,
      13_062_058_903,
      13_062_058_904,
      13_062_058_905,
      13_062_058_908,
      13_062_058_910,
      13_062_058_912,
      13_069_927_076,
      13_062_054_817,
      13_062_058_995,
      13_062_060_717,
      13_062_061_466,
      13_064_003_782,
      13_064_770_767,
      13_065_460_463,
      13_065_460_654,
      13_065_460_655,
      13_065_460_746,
      13_065_465_433,
      13_066_673_720,
      13_066_673_767,
      13_066_673_907,
      13_066_837_005,
      13_066_839_430,
      13_066_839_443,
      13_066_839_589,
      13_066_839_597,
      13_066_839_653,
      13_066_839_757,
      13_066_839_827,
      13_066_839_880,
      13_066_839_906,
      13_066_839_915,
      13_067_005_006,
      13_067_005_142,
      13_067_795_394,
      13_067_894_012,
      13_067_894_092,
      13_069_525_512,
      13_069_525_550,
      13_069_525_556,
      13_069_525_561,
      13_069_525_573,
      13_069_525_591,
      13_069_525_594,
      13_069_525_604,
      13_069_525_615,
      13_069_525_617,
      13_069_525_623,
      13_069_525_657,
      13_069_525_667,
      13_069_525_672,
      13_069_525_677,
      13_069_525_687,
      13_069_525_706,
      13_069_525_723,
      13_069_525_743,
      13_069_525_744,
      13_069_525_749,
      13_069_525_757,
      13_069_525_765,
      13_069_525_789,
      13_069_525_793,
      13_069_525_799,
      13_069_525_814,
      13_069_525_828,
      13_069_525_833,
      13_069_525_838,
      13_069_525_849,
      13_069_540_766,
      13_069_550_410,
      13_069_552_921,
      13_069_554_585,
      13_069_742_296,
      13_069_744_436,
      13_069_796_889,
      13_069_860_326,
      13_069_860_337,
      13_069_860_340,
      13_069_860_345,
      13_069_860_391,
      13_069_860_424,
      13_069_860_430,
      13_069_860_431,
      13_069_860_435,
      13_069_860_436,
      13_069_860_443,
      13_069_860_449,
      13_069_860_465,
      13_069_860_487,
      13_069_860_494,
      13_069_860_517,
      13_069_860_560,
      13_069_860_562,
      13_069_860_569,
      13_069_860_572,
      13_069_860_574,
      13_069_860_606,
      13_069_860_610,
      13_069_860_611,
      13_069_860_680,
      13_069_860_682,
      13_069_860_741,
      13_069_861_614,
      13_069_861_812,
      13_069_861_819,
      13_069_861_821,
      13_069_861_825,
      13_069_861_839,
      13_069_861_851,
      13_069_861_852,
      13_069_861_853,
      13_069_861_854,
      13_069_861_855,
      13_069_861_857,
      13_069_861_859,
      13_069_861_860,
      13_069_861_863,
      13_062_051_518,
      13_062_053_974,
      13_062_054_154,
      13_062_054_489,
      13_062_055_899,
      13_069_525_189,
      13_069_525_193,
      13_069_525_529,
      13_069_525_530,
      13_069_525_531,
      13_062_057_991,
      13_062_058_032,
      13_062_058_055,
      13_062_058_108,
      13_062_058_139,
      13_069_525_040,
      13_069_525_057,
      13_069_525_059,
      13_069_525_123,
      13_069_525_173,
      13_065_460_571,
      13_066_673_727,
      13_066_839_783,
      13_066_839_916,
      13_068_022_852,
      13_068_025_192,
      13_069_311_275,
      13_069_525_027,
      13_069_525_072,
      13_069_525_540,
      13_062_051_004,
      13_062_051_735,
      13_062_051_748,
      13_062_051_852,
      13_062_051_876,
      13_062_051_891,
      13_062_051_936,
      13_062_051_951,
      13_062_051_956,
      13_062_051_960,
      13_062_051_964,
      13_062_052_402,
      13_062_052_419,
      13_062_052_430,
      13_062_052_437,
      13_062_052_441,
      13_062_052_497,
      13_062_054_155,
      13_062_055_903,
      13_062_056_010,
      13_062_056_013,
      13_062_056_014,
      13_062_056_015,
      13_062_056_288,
      13_062_056_291,
      13_062_058_170,
      13_062_058_298,
      13_062_058_371,
      13_062_058_373,
      13_062_058_674,
      13_062_058_812,
      13_062_058_822,
      13_062_058_893,
      13_062_058_900,
      13_062_058_907,
      13_062_058_921,
      13_062_058_961,
      13_062_058_964,
      13_062_058_966,
      13_062_058_997,
      13_062_060_682,
      13_062_060_684,
      13_062_060_709,
      13_062_060_746,
      13_062_060_750,
      13_062_060_767,
      13_062_060_774,
      13_062_060_781,
      13_062_060_827,
      13_062_060_853,
      13_062_060_875,
      13_062_060_890,
      13_062_060_892,
      13_062_060_895,
      13_062_060_896,
      13_062_060_904,
      13_062_061_452,
      13_062_061_461,
      13_062_061_462,
      13_062_061_463,
      13_062_061_468,
      13_062_061_475,
      13_062_061_518,
      13_062_099_883,
      13_062_495_278,
      13_062_499_262,
      13_063_520_377,
      13_063_747_094,
      13_065_005_692,
      13_065_229_550,
      13_065_460_556,
      13_065_460_643,
      13_065_460_652,
      13_065_460_712,
      13_065_460_720,
      13_065_460_770,
      13_065_468_304,
      13_065_468_337,
      13_065_693_351,
      13_065_844_175,
      13_065_844_178,
      13_065_849_325,
      13_065_850_784,
      13_066_671_905,
      13_066_673_718,
      13_066_839_664,
      13_067_374_484,
      13_067_374_517,
      13_069_525_071,
      13_069_525_091,
      13_069_525_094,
      13_069_525_104,
      13_069_525_113,
      13_069_525_114,
      13_069_525_116,
      13_069_525_117,
      13_069_525_119,
      13_069_525_121,
      13_069_525_126,
      13_069_525_132,
      13_069_525_141,
      13_069_525_142,
      13_069_525_145,
      13_069_525_146,
      13_069_525_147,
      13_069_525_148,
      13_069_525_149,
      13_069_525_183,
      13_069_525_474,
      13_069_525_515,
      13_069_525_568,
      13_069_525_575,
      13_069_525_656,
      13_069_525_665,
      13_069_525_716,
      13_069_525_745,
      13_069_525_761,
      13_069_525_768,
      13_069_525_778,
      13_069_525_780,
      13_069_525_809,
      13_069_525_815,
      13_069_550_855,
      13_069_741_594,
      13_069_742_108,
      13_069_791_228,
      13_069_791_566,
      13_069_791_782,
      13_069_794_350,
      13_069_795_896,
      13_069_796_178,
      13_069_860_289,
      13_069_860_291,
      13_069_860_344,
      13_069_860_349,
      13_069_860_352,
      13_069_860_358,
      13_069_860_359,
      13_069_860_362,
      13_069_860_387,
      13_069_525_783,
      13_069_525_798,
      13_069_525_802,
      13_069_525_808,
      13_069_525_812,
      13_069_525_819,
      13_069_742_419,
      13_069_747_935,
      13_069_791_492,
      13_069_860_296,
      13_069_860_307,
      13_069_860_311,
      13_069_860_314,
      13_069_860_317,
      13_069_860_319,
      13_069_860_327,
      13_069_860_328,
      13_069_860_329,
      13_069_860_341,
      13_069_860_343,
      13_062_051_220,
      13_062_051_599,
      13_062_051_611,
      13_062_051_787,
      13_062_051_788,
      13_062_051_857,
      13_062_051_971,
      13_062_052_158,
      13_062_052_269,
      13_062_052_453,
      13_062_051_312,
      13_062_051_329,
      13_062_051_334,
      13_062_051_346,
      13_062_051_418,
      13_062_051_446,
      13_062_051_941,
      13_062_051_959,
      13_062_051_970,
      13_062_052_006,
      13_062_052_027,
      13_062_052_095,
      13_062_052_096,
      13_062_052_213,
      13_062_052_241,
      13_062_052_329,
      13_062_055_165,
      13_062_058_667,
      13_062_058_963,
      13_062_060_692,
      13_062_492_787,
      13_066_673_891,
      13_066_839_594,
      13_066_839_626,
      13_066_839_804,
      13_069_525_134,
      13_069_525_143,
      13_069_525_164,
      13_069_525_181,
      13_069_525_190,
      13_069_525_669,
      13_069_525_733,
      13_069_525_786,
      13_069_525_818,
      13_069_793_331,
      13_069_794_428,
      13_069_860_339,
      13_069_860_510,
      13_069_860_548,
      13_069_860_717,
      13_069_861_816,
      13_069_861_831,
      13_069_861_871,
      13_069_861_872,
      13_069_861_882,
      13_069_861_883,
      13_069_861_892,
      13_069_861_894,
      13_069_861_915,
      13_069_861_916,
      13_069_861_917,
      13_069_861_926,
      13_069_861_930,
      13_069_861_959,
      13_069_861_961,
      13_069_861_963,
      13_069_861_991,
      13_069_861_995,
      13_069_861_996,
      13_069_861_998,
      13_069_862_614,
      13_069_862_620,
      13_069_862_626,
      13_069_862_628,
      13_069_862_648,
      13_069_862_680,
      13_069_862_690,
      13_069_864_611,
      13_069_864_614,
      13_069_864_615,
      13_069_864_618,
      13_069_864_625,
      13_069_864_635,
      13_069_864_641,
      13_069_864_642,
      13_069_864_655,
      13_069_864_659,
      13_069_864_661,
      13_069_864_665,
      13_069_864_677,
      13_069_864_688,
      13_069_864_691,
      13_069_864_704,
      13_069_864_708,
      13_069_864_712,
      13_069_864_719,
      13_069_864_721,
      13_069_864_724,
      13_069_864_728,
      13_069_864_731,
      13_069_864_732,
      13_069_864_733,
      13_069_864_739,
      13_069_864_741,
      13_069_864_742,
      13_069_864_755,
      13_069_864_757,
      13_069_864_760,
      13_069_864_762,
      13_069_864_767,
      13_069_864_768,
      13_069_864_769,
      13_069_864_770,
      13_069_864_774,
      13_069_864_775,
      13_069_864_776,
      13_069_864_778,
      13_069_864_784,
      13_069_864_785,
      13_069_864_786,
      13_069_864_787,
      13_069_864_788,
      13_069_864_789,
      13_069_864_790,
      13_069_864_791,
      13_069_864_792,
      13_069_864_793,
      13_069_864_795,
      13_069_864_799,
      13_069_864_812,
      13_069_864_916,
      13_069_864_919,
      13_069_864_923,
      13_069_864_924,
      13_069_864_925,
      13_069_864_926,
      13_069_864_927,
      13_069_864_928,
      13_069_864_929,
      13_069_864_931,
      13_069_864_932,
      13_069_864_934,
      13_069_864_935,
      13_069_864_936,
      13_069_864_937,
      13_069_864_962,
      13_069_864_964,
      13_069_864_966,
      13_069_864_967,
      13_069_864_968,
      13_069_864_970,
      13_069_864_971,
      13_069_864_972,
      13_069_864_974,
      13_069_864_975,
      13_069_867_208,
      13_069_867_209,
      13_069_867_216,
      13_069_867_217,
      13_069_867_219,
      13_069_867_231,
      13_069_867_252,
      13_069_867_446,
      13_069_868_740,
      13_069_868_742,
      13_069_868_743,
      13_069_868_744,
      13_069_868_754,
      13_069_868_761,
      13_069_868_774,
      13_069_868_778,
      13_069_868_782,
      13_069_868_786,
      13_069_868_790,
      13_069_868_798,
      13_069_868_799,
      13_069_868_803,
      13_069_868_806,
      13_069_868_808,
      13_069_868_809,
      13_069_868_810,
      13_069_868_813,
      13_069_868_815,
      13_069_868_839,
      13_069_868_842,
      13_069_868_850,
      13_069_920_614,
      13_069_920_615,
      13_069_920_646,
      13_069_925_603,
      13_069_925_841,
      13_069_927_283,
      13_069_927_347,
      13_069_927_352,
      13_069_927_480,
      13_069_927_481,
      13_069_927_517,
      13_069_927_803,
      13_069_927_870,
      13_069_928_115,
      13_069_928_122,
      13_069_928_136,
      13_069_928_279,
      13_069_928_328,
      13_069_928_350,
      13_069_944_342,
      13_069_944_344,
      13_069_946_343,
      13_062_051_307,
      13_062_051_534,
      13_062_060_847,
      13_062_060_894,
      13_066_510_464,
      13_066_521_077,
      13_066_671_982,
      13_066_673_756,
      13_066_674_099,
      13_069_318_041,
      13_069_522_761,
      13_069_525_090,
      13_069_525_097,
      13_069_525_199,
      13_069_525_472
    ]

    b = [
      13_062_058_514,
      13_062_058_515,
      13_062_058_516,
      13_062_058_517,
      13_062_058_518,
      13_062_058_519,
      13_062_058_521,
      13_062_058_522,
      13_062_058_523,
      13_062_058_524,
      13_062_058_526,
      13_062_058_527,
      13_062_058_528,
      13_062_058_529,
      13_062_058_530,
      13_062_058_531,
      13_062_058_532,
      13_062_058_533,
      13_062_058_534,
      13_062_058_535,
      13_062_058_536,
      13_062_058_537,
      13_062_058_538,
      13_062_058_539,
      13_062_058_540,
      13_062_058_543,
      13_062_058_545,
      13_062_058_546,
      13_062_058_547,
      13_062_058_549,
      13_062_058_551,
      13_062_058_552,
      13_062_058_553,
      13_062_058_554,
      13_062_058_555,
      13_062_058_556,
      13_062_058_558,
      13_062_058_559,
      13_062_058_560,
      13_062_058_563,
      13_062_058_564,
      13_062_058_565,
      13_062_058_566,
      13_062_058_568,
      13_062_058_569,
      13_062_058_570,
      13_062_058_571,
      13_062_058_572,
      13_062_058_574,
      13_062_058_575
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
        user.numbers.create(user_id: user.id, number: n, friendly_name: fn, country: 'CA', default: default, provider: 'nexmo', price: '210')
        # TextingService.update_nexmo_number('CA', n, 'tel', '<redacted_phone_number>')
      else
        puts "CANT BUY #{n}"
      end
    end
  end

  def qawc
    ary = [
      13_062_058_514,
      13_062_058_515,
      13_062_058_516,
      13_062_058_517,
      13_062_058_518,
      13_062_058_519,
      13_062_058_521,
      13_062_058_522,
      13_062_058_523,
      13_062_058_524,
      13_062_058_526,
      13_062_058_527,
      13_062_058_528,
      13_062_058_529,
      13_062_058_530,
      13_062_058_531,
      13_062_058_532,
      13_062_058_533,
      13_062_058_534,
      13_062_058_535,
      13_062_058_536,
      13_062_058_537,
      13_062_058_538,
      13_062_058_539,
      13_062_058_540,
      13_062_058_543,
      13_062_058_545

    ]

    # user = nil
    user = User.find_by(email: '<redacted_email>'.downcase)

    ary.each_with_index do |n, _i|
      n = n.to_s
      # user = User.find_by(email: "ontariostrong#{n[1..3]}<redacted_email>")

      next unless user

      res = TextingService.buy_number_nexmo('CA', n)

      if res
        # default = i == 0 ? 1 : 0
        default = 0
        fn = '(' + n[1..3] + ') ' + n[4..6] + '-' + n[7..10]
        user.numbers.create(user_id: user.id, number: n, friendly_name: fn, country: 'CA', default: default, provider: 'nexmo', price: '210')
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
    s = UserList.where(customer_contact_id: mcids, customer_contact_type: 'MerchantContact').where('created_at > ?', Time.now - 10.days)

    puts phone_numbers.length.inspect
    puts mcids.length.inspect
    puts s.length.inspect
    # s.delete_all
  end

  def wq
    emails = %w[<redacted_email> <redacted_email> <redacted_email> <redacted_email> <redacted_email> <redacted_email>]
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
    file_data = CSV.read('/home/taiwo/Downloads/Rules to add to funnel accounts - Sep 2.csv', encoding: 'ISO-8859-1', headers: true, skip_blanks: true, header_converters: :symbol, converters: %i[all blank_to_nil], skip_lines: /^(?:[,:;]\s*)+$/)

    data = []
    file_data.each do |row|
      row = row.to_hash
      user_ids.each { |uid| data << { user_id: uid, text: row[:text], rule_type: row[:rule_type], response: row[:response] } }
      if data.length == 5000
        Rule.import data, validate: false
        data.clear
      end
    end
    Rule.import(data, validate: false) if data.present?
  end

  def wq3
    rules = Rule.where(user_id: 220253).pluck(:text, :rule_type, :response, :message_length)

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
end
