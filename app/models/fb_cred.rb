class FbCred < ActiveRecord::Base

  belongs_to :user
  scope :original_cred, -> { where.not(auth_token: nil) }

  def self.from_omniauth(auth, id)
    begin
      where(user_id: id, page_specific_id: nil).first_or_initialize.tap do |fb_cred|
        fb_cred.fb_id = auth.uid
        fb_cred.auth_token = auth.credentials.token
        fb_cred.email = auth.info.email
        fb_cred.name = auth.info.name
        fb_cred.profile_pic_url = FacebookMessengerService.get_profile_pic(auth.credentials.token, auth.uid)
        fb_cred.time_zone = (User.find id).time_zone
        fb_cred.save
        GetIntelligenceDataJob.perform_later(fb_cred.email, 'FullContact')
        reverse_link_account(fb_cred)
      end
      true
    rescue StandardError => err
      false
    end
  end

  def self.add_fb_user_from_messenger(fb_page, new_user_id)
    begin
      page_access_token = fb_page.page_access_token
      user_data = FacebookMessengerService.get_user_info(page_access_token, new_user_id)
      full_name = user_data['first_name'] + ' ' + user_data['last_name']
      url = user_data['profile_pic']
      timezone = ActiveSupport::TimeZone.new(user_data['timezone']).tzinfo.name
      gender = user_data['gender']
      link_response = link_page_specific_user(url)
      welcome_text = "Welcome #{full_name} to Relay-Message Commerce platform"
      @fb_cred = FbCred.find_or_initialize_by(page_specific_id: new_user_id)
      if link_response.present?
        @fb_cred.update(
          name: full_name, gender: gender,
          email: link_response[:email],
          time_zone: timezone, profile_pic_url: url,
          fb_id: link_response[:fb_id],
          user_id: link_response[:user_id],
          fb_page_id: fb_page.id
        )
      else
        send_auth_link(page_access_token, new_user_id, welcome_text)
        @fb_cred.update(
          name: full_name,time_zone: timezone,
          gender: gender, profile_pic_url: url,
          fb_page_id: fb_page.id
        )
      end
      @fb_cred if @fb_cred.save
    rescue StandardError => err
    end
  end

  private

  def self.send_auth_link(page_access_token, new_user_id, welcome_text)
    last_account_link_message = FbMessage.where(text: '', to: new_user_id).last
    if last_account_link_message.nil? || (last_account_link_message.images.empty? && last_account_link_message.created_at < Time.current.beginning_of_day)
      FacebookMessengerService.send_auth_link(page_access_token, new_user_id, welcome_text)
    end
  end

  #link facebook page specific user to Merchant
  def self.link_page_specific_user(pic_url)
    response = {}
    user_identifier = extract_profile_pic_identifier(pic_url)
    all_user_fb_cred = FbCred.where.not(fb_id: nil)
                                        .where(page_specific_id: nil)
    all_user_fb_cred.each do |cred|
      if extract_profile_pic_identifier(cred.profile_pic_url) == user_identifier
        response = { fb_id: cred.fb_id, email: cred.email, user_id: cred.user_id }
      end
    end
    response
  end

  def self.reverse_link_account(fb_cred)
    user_identifier = extract_profile_pic_identifier(fb_cred.profile_pic_url)
    unlinked_fb_creds = FbCred.where(fb_id: nil)
                              .where.not(page_specific_id: nil)
    unlinked_fb_creds.each do |cred|
      if extract_profile_pic_identifier(cred.profile_pic_url) == user_identifier
        cred.update(fb_id: fb_cred.fb_id, email: fb_cred.email, user_id: fb_cred.user_id)
      end
    end
  end

  # extract user identifier from profile picture
  def self.extract_profile_pic_identifier(pic_url)
    url = pic_url.match(/^.+\/[\w:]+\.(jpe?g|png|gif)/i).to_a.first
    name = url.split('/').last
    name_array = name.split('_')
    name_array.shift
    name_array.pop
    pic_identifier = name_array.join('_')
    pic_identifier
  end

end
