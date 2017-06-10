class HostedSmsService
  class <<self
  TWILIO_API_KEY = Rails.application.secrets.twilio["key"]
  TWILIO_API_SECRET = Rails.application.secrets.twilio["secret"]

  def init_hosted_sms(options)
    begin
      @client = Twilio::REST::Client.new(TWILIO_API_KEY, TWILIO_API_SECRET)
      response = @client.preview.hosted_numbers.hosted_number_orders.create(options)
      create_hosted_number_order(response)
    rescue StandardError => err
    end
  end

  def get_status(h)
    @client = Twilio::REST::Client.new(TWILIO_API_KEY, TWILIO_API_SECRET)
    response = @client.preview.hosted_numbers.hosted_number_orders(h.sid).fetch
    update_status(h, response)
  end

  def request_loa(h)
    # response = HTTParty.post(
    #   h.url,
    #   basic_auth: { username: <redacted_username>
    #   headers: { 'Content-Type' => 'application/json' },
    #   body: {
    #     Status:'pending-loa'
    #   }.to_json
    # )
    # update_status(h, response)
    @client = Twilio::REST::Client.new(TWILIO_API_KEY, TWILIO_API_SECRET)
    hosted_number_order = @client.preview.hosted_numbers.hosted_number_orders(h.sid)
    response = hosted_number_order.update(status: 'pending-loa')
    update_status(h, response)
  end

  def update(h, options)
    @client = Twilio::REST::Client.new(TWILIO_API_KEY, TWILIO_API_SECRET)
    hosted_number_order = @client.preview.hosted_numbers.hosted_number_orders(h.sid)
    response = hosted_number_order.update(options)
    update_status(h, response)
  end

  private

    def create_hosted_number_order(response)
      HostedSms.create(
        phone_number: response[:phone_number],
        status: response[:status],
        unique_name: response[:unique_name],
        date_updated: response[:date_updated],
        cc_emails: response[:cc_emails],
        friendly_name: response[:friendly_name],
        capabilities: response[:capabilities],
        incoming_phone_number_sid: response[:incoming_phone_number_sid],
        url: response[:url],
        address_sid: response[:address_sid],
        sid: response[:sid],
        date_created: response[:date_created],
        account_sid: response[:account_sid],
        email: response[:email],
        signing_document_sid: response[:signing_document_sid]
      )
    end

    def update_status(h, response)
      h.update(
        phone_number: response[:phone_number],
        status: response[:status],
        unique_name: response[:unique_name],
        date_updated: response[:date_updated],
        cc_emails: response[:cc_emails],
        friendly_name: response[:friendly_name],
        capabilities: response[:capabilities],
        incoming_phone_number_sid: response[:incoming_phone_number_sid],
        url: response[:url],
        address_sid: response[:address_sid],
        sid: response[:sid],
        date_created: response[:date_created],
        account_sid: response[:account_sid],
        email: response[:email],
        signing_document_sid: response[:signing_document_sid]
      )
    end

end
