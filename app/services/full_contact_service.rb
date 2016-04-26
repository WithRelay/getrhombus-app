class FullContactService

  FullContact.configure do |config|
    config.api_key = Rails.application.secrets.fullcontact["key"]
    # config.skip_rubyize = true
  end

  class << self
    
    def get_fullcontact_info(email)
      begin
        person = FullContact.person(email: email)
        FullContactData.add_or_update_fullcontact_data(email, person) if person
        person
      rescue StandardError => err
        nil
      end
    end

  end



end
