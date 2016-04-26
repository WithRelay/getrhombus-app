class OpenCnamService

  ACCOUNT_SID = Rails.application.secrets.opencnam["sid"]
  AUTH_TOKEN = Rails.application.secrets.opencnam["token"]

  class << self

    def get_opencnam_info(phone)
      begin
        client = Opencnam::Client.new(:account_sid => ACCOUNT_SID, :auth_token => AUTH_TOKEN, :use_ssl => true)
        data = client.phone("+#{phone}", :format => :json)
        OpenCnamData.add_or_update_opencnam_data(phone, data) if data
        data
      rescue StandardError => err
        nil
      end
    end

  end

end