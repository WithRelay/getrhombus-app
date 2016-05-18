require 'uri'
  
  # help thorough implementation needed per doc above

class TextingService

  NEXMO_API_KEY = Rails.application.secrets.nexmo["key"]
  NEXMO_API_SECRET = Rails.application.secrets.nexmo["secret"]

  TWILIO_API_KEY = Rails.application.secrets.twilio["key"]
  TWILIO_API_SECRET = Rails.application.secrets.twilio["secret"]
  TWILIO_API_PHONE = Rails.application.secrets.twilio["phone"]
  TWILIO_RHOMBUS_APP_SID = Rails.application.secrets.twilio["rhombus_app_sid"]

  class << self

    def send_sms_nexmo(from, to, message)
      begin
        # encode the nexmo uri
        uri = URI.encode_www_form([["api_key",NEXMO_API_KEY], ["api_secret", NEXMO_API_SECRET], ["from", from], ["to", to], ["text", message]])   
        response = HTTParty.post('https://rest.nexmo.com/sms/json?'+ uri, :headers => {"Content-Type" => "application/x-www-form-urlencoded"} )
      rescue StandardError => err
        return err
      end
    end
  
    def send_sms(from, to, body, media_url = nil)
      begin
        client = Twilio::REST::Client.new TWILIO_API_KEY, TWILIO_API_SECRET
        data = { From: from, To: to, Body: body, ApplicationSid: TWILIO_RHOMBUS_APP_SID } 
        data[:media_url] = media_url if media_url  # US and canadian phone numbers can make use of an image as well.
        message = client.account.messages.create(data)
      rescue StandardError => err
        return err
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

    def buy_number(num)
      begin  
        client = Twilio::REST::Client.new TWILIO_API_KEY, TWILIO_API_SECRET
        number = client.account.incoming_phone_numbers.create(:phone_number => num, :VoiceApplicationSid => TWILIO_RHOMBUS_APP_SID,
         :SmsApplicationSid => TWILIO_RHOMBUS_APP_SID)    
        return true    
      rescue StandardError => e
        return false
      end
    end

    def search_number(str, with, country)
      # https://www.twilio.com/help/faq/phone-numbers/which-countries-does-twilio-have-phone-numbers-in-and-what-are-their-capabilities
      client = Twilio::REST::Client.new TWILIO_API_KEY, TWILIO_API_SECRET
      begin
        search_params[with] = str
        twilio_list[country.to_sym][:types][type.to_sym][:capabilities].each do |c|

        end

        search_params = { sms_enabled: "true" }    
        search_params = { voice_enabled: "true", mms_enabled: "true", exclude_all_address_required: "true" }
        

        numbers = client.account.available_phone_numbers.get(country).local.list(search_params)[0..4]
        return numbers.map { |p| p.phone_number } 
      rescue StandardError => e
          return e.message #[]
      end
    end

    def twilio_list
      {       
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
        HU: {
          name: "Hungary",
          types: {
            mobile: {
              capabilities: ["sms"], 
              reach: "domestic",
              address_required: ""
            },
          }
        },
        IL: {
          name: "Israel",
          types: {
            mobile: {
              capabilities: ["sms"],
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
        MX: {
          name: "Mexico",
          types: {
            mobile: {
              capabilities: ["sms"],
              reach: "domestic",
              address_required: "foreign address"
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
          name: "Puerto Rice",
          types: {
            local: {
              capabilities: ["sms", "voice"],
              reach: "global",
              address_required: ""
            },
          }
        },
        ES: {
          name: "Spain",
          types: {  
            local: {
              capabilities: ["sms", "voice"],
              reach: "domestic",
              address_required: "local address"
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
            mobile: {
              capabilities: ["sms"],
              reach: "global",
              address_required: ""
            },
            national: {
              capabilities: ["voice"],
              reach: "domestic",
              address_required: ""
            },
            toll_free: {
              capabilities: ["voice"],
              reach: "domestic",
              address_required: ""
            },
          }
        },
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
  end
end

