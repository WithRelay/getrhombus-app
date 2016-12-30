class FbCred < ActiveRecord::Base

  belongs_to :user
  has_many :fb_pages, dependent: :destroy

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
      # welcome_text = "Welcome #{full_name} to Rhombus-Message Commerce platform"
      if link_response.present?
        # FacebookMessengerService.send_text_message(page_access_token, new_user_id, welcome_text)
        # FacebookMessengerService.send_attachment(page_access_token, new_user_id, 'image', 'http://www.compustarltd.com/wp-content/uploads/2015/11/welcome.png')
        fb_cred = FbCred.new(
          name: full_name, page_specific_id: new_user_id,
          email: link_response[:email], fb_id: link_response[:fb_id],
          time_zone: timezone, gender: gender, profile_pic_url: url,
          user_id: link_response[:user_id]
        )
      else
        FacebookMessengerService.send_auth_link(page_access_token, new_user_id, welcome_text)
        fb_cred = FbCred.new(
          name: full_name, page_specific_id: new_user_id,
          time_zone: timezone, gender: gender, profile_pic_url: url
        )
      end
      fb_cred.save    
    rescue StandardError => err
    end
  end

  private
  
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

  #link facebook page specific user to Merchant
  def self.link_page_specific_user(pic_url)
    response = {}
    user_identifier = extract_profile_pic_identifier(pic_url)
    all_user_fb_cred = FbCred.where.not('user_id' => nil)
    all_user_fb_cred.each do |cred|
      if extract_profile_pic_identifier(cred.profile_pic_url) == user_identifier
        response = { fb_id: cred.fb_id, email: cred.email, user_id: cred.user_id }
      end      
    end  
    response   
  end

end
