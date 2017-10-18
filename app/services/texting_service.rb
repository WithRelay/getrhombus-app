require 'uri'

  # help thorough implementation needed per doc above

class TextingService

  NEXMO_API_KEY = Rails.application.secrets.nexmo["key"]
  NEXMO_API_SECRET = Rails.application.secrets.nexmo["secret"]

  TWILIO_API_KEY = Rails.application.secrets.twilio["key"]
  TWILIO_API_SECRET = Rails.application.secrets.twilio["secret"]
  TWILIO_RHOMBUS_APP_SID = Rails.application.secrets.twilio["rhombus_app_sid"]

  FIBERNETICS_API_KEY = Rails.application.secrets.fibernetics["key"]   #GetRhombusTest
  FIBERNETICS_API_SECRET = Rails.application.secrets.fibernetics["secret"] #qZAmwz9m8Z6b
  FIBERNETICS_BASE_URL = "https://smsadmin.fongo.com"
  FIBERNETICS_PN = "<redacted_phone_number>"

  class << self

    def send_sms_nexmo(from, to, message, client_ref)
      begin
        from = from[1..-1] if from.chr == "+"
        to = to[1..-1] if to.chr == "+"

        # encode the nexmo uri
        uri = URI.encode_www_form([["api_key", NEXMO_API_KEY], ["api_secret", NEXMO_API_SECRET], ["from", from], ["to", to], ["text", message], ['client-ref', client_ref]])
        # ["status-report-req", 1]
        [true, HTTParty.post('https://rest.nexmo.com/sms/json?'+ uri, :headers => {"Content-Type" => "application/x-www-form-urlencoded"})]
      rescue StandardError => err
        [false, err]
      end
    end

    def send_sms(from, to, body, media_ary = [])
      begin
        from = "+" + from if from.chr != "+"
        to = "+" + to if to.chr != "+"

        client = Twilio::REST::Client.new TWILIO_API_KEY, TWILIO_API_SECRET
        data = { from: from, to: to, body: body, application_sid: TWILIO_RHOMBUS_APP_SID }
        # 5MB max size, 10 images max
        data[:media_url] = media_ary if media_ary.present?
        # https://www.twilio.com/docs/api/rest/message
        [true, client.api.messages.create(data)]
      rescue StandardError => err
        [false, err]
      end
    end

    def send_sms_fibernetics(from, to, body, subscriber_id)
      begin
        uri = URI.encode_www_form([ ["account_id", FIBERNETICS_API_KEY], ["auth_token", FIBERNETICS_API_SECRET], 
                                    ["phone_number", from], ["to", to], ["message", body], ['subscriber_id', subscriber_id] ])        
        return HTTParty.post("https://smssend.fongo.com/Send.ashx?#{uri}", headers: { "Content-Type" => "application/x-www-form-urlencoded" })
      rescue Timeout::Error => err
        ExceptionNotifier.notify_exception(err, env: Rails.env, data: { message: "In create_fibernetics_subscriber timeout" })
      rescue StandardError => err
        ExceptionNotifier.notify_exception(err, env: Rails.env, data: { message: "In create_fibernetics_subscriber" })
      end
      nil
    end

    def get_sms_fibernetics(phone_number, since_id, subscriber_id)
      begin
        uri = URI.encode_www_form([ ["account_id", FIBERNETICS_API_KEY], ["auth_token", FIBERNETICS_API_SECRET], 
                                    ["phone_number", phone_number], ["since_id", since_id], ['subscriber_id', subscriber_id] ])        
        return HTTParty.post("https://smsfetch.fongo.com/FetchMessageHandler.ashx?#{uri}", headers: { "Content-Type" => "application/x-www-form-urlencoded" })
      rescue Timeout::Error => err
        ExceptionNotifier.notify_exception(err, env: Rails.env, data: { message: "In get_sms_fibernetics timeout" })
      rescue StandardError => err
        ExceptionNotifier.notify_exception(err, env: Rails.env, data: { message: "In get_sms_fibernetics" })
      end
      nil
    end

    def create_fibernetics_subscriber(fn_num)
      begin
        uri = URI.encode_www_form([ ["account_id", FIBERNETICS_API_KEY], ["auth_token", FIBERNETICS_API_SECRET], ["phone_number", fn_num] ])
        re = HTTParty.post(FIBERNETICS_BASE_URL + "/CreateSubscriber.ashx?#{uri}", headers: { "Content-Type" => "application/x-www-form-urlencoded" })
        return re['response']['account']['account_id'] if re.code == 200 && re['response']['status'] == "OK"
      rescue Timeout::Error => err
        ExceptionNotifier.notify_exception(err, env: Rails.env, data: { message: "In create_fibernetics_subscriber timeout" })
      rescue StandardError => err
        ExceptionNotifier.notify_exception(err, env: Rails.env, data: { message: "In create_fibernetics_subscriber" })
      end
      nil
    end

    def buy_number(params)
      begin
        client = Twilio::REST::Client.new TWILIO_API_KEY, TWILIO_API_SECRET
        re = search_number(params)
        if re[:number].present?
          # https://www.twilio.com/docs/api/rest/incoming-phone-numbers
          re = client.incoming_phone_numbers.create(phone_number: re[:number], voice_application_sid: TWILIO_RHOMBUS_APP_SID,
                sms_application_sid: TWILIO_RHOMBUS_APP_SID)
          return re.phone_number.gsub('+', ''), re.friendly_name
        end
      rescue Twilio::REST::RestException
      rescue StandardError => e
      end
      false
    end

    def search_number(params)
      begin
        # https://www.twilio.com/help/faq/phone-numbers/which-countries-does-twilio-have-phone-numbers-in-and-what-are-their-capabilities
        client = Twilio::REST::Client.new TWILIO_API_KEY, TWILIO_API_SECRET

        search_params = {}
        search_params[ ((['US', 'CA'].include? params[:country]) ? 'area_code' : 'contains').to_sym ] = params[:query]
        data = twilio_list[params[:country].to_sym][:types][params[:type].to_sym]
        data[:capabilities].each { |c| search_params[(c + '_enabled').to_sym] = "true" }
        search_params[:exclude_all_address_required] = "true" if data[:address_required] == ""

        if params[:type] == 'local'
          # https://www.twilio.com/docs/api/rest/available-phone-numbers
          number = client.api.available_phone_numbers(params[:country]).local.list(search_params).first
        elsif params[:type] == 'toll_free'
          number = client.api.available_phone_numbers(params[:country]).toll_free.list(search_params).first
        elsif params[:type] == 'mobile'
          number = client.api.available_phone_numbers(params[:country]).mobile.list(search_params).first
        end

        { number: number.nil? ? '' : number.phone_number  }
      rescue Twilio::REST::RestException
        { error: "Twilio cannot provision the number." }
      rescue StandardError => e
        { error: e.message }
      end
    end

    def number_lookup(num)
      begin
        client = Twilio::REST::Client.new TWILIO_API_KEY, TWILIO_API_SECRET
        number = client.lookups.v1.phone_numbers(num).fetch
        #number.national_format
        [number.phone_number[1..-1], number.country_code]
      rescue Twilio::REST::RestException
        false
      rescue StandardError => e
        false
      end
    end

    def twilio_list
      {
=begin
        AU: {
          name: "Australia",
          types: {
            mobile: {
              capabilities: ["sms"],
              reach: "global",
              address_required: ""
            },
          }
         },
        AT: {
          name: 'Austria',
          types: {
            mobile: {
              capabilities: ["sms"],
              reach: "global",
              address_required: ""
            },
          }
        },
        BE: {
          name: "Belgium",
          types: {
            mobile: {
              capabilities: ["sms"],
              reach: "global",
              address_required: ""
            },
          }
        },
=end
        CA: {
          name: "Canada",
          types: {
           local: {
              capabilities: ["sms", "mms", "voice"],
              reach: "global",
              address_required: ""
            },
            toll_free: {
              capabilities: ["sms", "voice"],
              reach: "domestic",
              address_required: ""
            },
          }
        },
=begin
        CL: {
          name: "Chile",
          types: {
            mobile: {
              capabilities: ["sms"],
              reach: "domestic",
              address_required: ""
            },
          }
        },
        CZ: {
          name: "Czech Republic",
          types: {
            mobile: {
              capabilities: ["sms"],
              reach: "domestic",
              address_required: ""
            },
          }
        },
        EE: {
          name: "Estonia",
          types: {
            mobile: {
              capabilities: ["sms"],
              reach: "global",
              address_required: ""
            },
          }
        },
        FI: {
          name: "Finland",
          types: {
            mobile: {
              capabilities: ["sms"],
              reach: "global",
              address_required: ""
            },
          }
        },
        FR: {
          name: "France",
          types: {
            mobile: {
              capabilities: ["sms", "voice"],
              reach: "domestic",
              address_required: "any address"
            },
          }
        },
        DE: {
          name: "Germany",
          types: {
            mobile: {
              capabilities: ["sms", "voice"],
              reach: "global",
              address_required: "any address"
            },
          }
        },
        HK: {
          name: "Hong Kong",
          types: {
            mobile: {
              capabilities: ["sms"],
              reach: "domestic",
              address_required: ""
            },
          }
        },
        HU: {
          name: "Hungary",
          types: {
            mobile: {
              capabilities: ["sms"],
              reach: "global",
              address_required: ""
            },
          }
        },
        IE: {
          name: "Ireland",
          types: {
            mobile: {
              capabilities: ["sms"],
              reach: "global",
              address_required: ""
            },
          }
        },
        IL: {
          name: "Israel",
          types: {
            mobile: {
              capabilities: ["sms", 'voice'],
              reach: "global",
              address_required: ""
            },
          }
        },
        LT: {
          name: "Lithuania",
          types: {
            mobile: {
              capabilities: ["sms"],
              reach: "domestic",
              address_required: ""
            },
          }
        },
        MY: {
          name: "Malaysia",
          types: {
            mobile: {
              capabilities: ["sms"],
              reach: "domestic",
              address_required: ""
            },
          }
        },
        NL: {
          name: "Netherlands",
          types: {
            mobile: {
              capabilities: ["sms"],
              reach: "global",
              address_required: "any address"
            },
          }
        },
        NO: {
          name: "Norway",
          types: {
            mobile: {
              capabilities: ["sms"],
              reach: "global",
              address_required: ""
            },
          }
        },
        PL: {
          name: "Poland",
          types: {
            mobile: {
              capabilities: ["sms"],
              reach: "global",
              address_required: ""
            },
          }
        },
        PR: {
          name: "Puerto Rico",
          types: {
            local: {
              capabilities: ["sms", "voice"],
              reach: "global",
              address_required: ""
            },
          }
        },
        SE: {
          name: "Sweden",
          types: {
            mobile: {
              capabilities: ["sms"],
              reach: "global",
              address_required: ""
            },
          }
        },
        CH: {
          name: "Switzerland",
          types: {
            mobile: {
              capabilities: ["sms"],
              reach: "global",
              address_required: ""
            },
          }
        },
        GB: {
          name: "United Kingdom",
          types: {
            local: {
              capabilities: ["sms", "voice"],
              reach: "domestic",
              address_required: ""
            },
          }
        },
=end
        US: {
          name: "United States",
          types: {
            local: {
              capabilities: ["sms", "mms", "voice"],
              reach: "global",
              address_required: ""
            },
            toll_free: {
              capabilities: ["sms", "voice"],
              reach: "domestic",
              address_required: ""
            },
          }
        },
      }
    end

    def release_number(num)
      begin
        client = Twilio::REST::Client.new TWILIO_API_KEY, TWILIO_API_SECRET
        # https://www.twilio.com/docs/api/rest/incoming-phone-numbers
        client.incoming_phone_numbers.list({phone_number: num}).each { |n| n.delete }
        true
      rescue StandardError => e
        false
      end
    end

    # it fetches all message information since only limited message response we got from webhook for sent/received message
    def fetch_message_details(message_id)
      begin
        client = Twilio::REST::Client.new TWILIO_API_KEY, TWILIO_API_SECRET
        # https://www.twilio.com/docs/api/rest/message
        client.api.messages(message_id).fetch
      rescue StandardError => e
        false
      end
    end

    def receive_call
      response = Twilio::TwiML::Response.new do |r|
        # Should be your Twilio Number or a verified Caller ID
        r.Dial :callerId => '+<redacted_phone_number>' do |d|
            d.Client 'rho-jenny'
        end
      end
      return response
    end

    def get_twilio_capibility_token
      # This application sid will play a Welcome Message.
      demo_app_sid = '<redacted_twilio_app_sid>'
      capability = Twilio::Util::Capability.new TWILIO_API_KEY, TWILIO_API_SECRET
      capability.allow_client_outgoing '<redacted_twilio_app_sid>'
      capability.allow_client_incoming "rho-jenny"
      token = capability.generate
      return token
    end

  end
end
