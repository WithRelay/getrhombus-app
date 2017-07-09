class HostedSmsService
  class <<self
    TWILIO_API_KEY = Rails.application.secrets.twilio["key"]
    TWILIO_API_SECRET = Rails.application.secrets.twilio["secret"]
    ADDRESS_SID = 'AD577a66551b627230456bca51d5f82a89'

    def init_hosted_sms(user, params)
      # @client.preview.hosted_numbers.hosted_number_orders.create(
      # phone_number: '<redacted_phone_number>' ,
      # type:'local', iso_country:'US', address_sid:ADDRESS_SID ,
      # email: merchant_email,
      # cc_emails: ['team_email'], sms_capability:true, friendly_name: 'Business_name_number')
      params = params[:user].permit(:phone_number, :rn_country)
      begin
        @client = Twilio::REST::Client.new(TWILIO_API_KEY, TWILIO_API_SECRET)
        response = @client.preview.hosted_numbers.hosted_number_orders.create(
          cc_emails: [],
          phone_number: params[:phone_number],
          type: 'local',
          iso_country: params[:rn_country],
          address_sid: ADDRESS_SID,
          email: user.email,
          sms_capability: true
        )
        create_hosted_number_order(user, response)
        [true, 'Hosted number order started']
      rescue StandardError => err
        # email team here
        [false, err.message]
      end
    end

    def get_status(h)
      begin
        @client = Twilio::REST::Client.new(TWILIO_API_KEY, TWILIO_API_SECRET)
        response = @client.preview.hosted_numbers.hosted_number_orders(h.sid).fetch
        update_status(h, response)
      rescue StandardError => err
      end
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
      begin
        @client = Twilio::REST::Client.new(TWILIO_API_KEY, TWILIO_API_SECRET)
        hosted_number_order = @client.preview.hosted_numbers.hosted_number_orders(h.sid)
        response = hosted_number_order.update(status: 'pending-loa')
        update_status(h, response)
      rescue StandardError => e
        # sent email to team about error
      end
    end

    private

      def create_hosted_number_order(user, response)
        user.create_hosted_sms(
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
          signing_document_sid: response[:signing_document_sid],
          status_events: {}
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
end
