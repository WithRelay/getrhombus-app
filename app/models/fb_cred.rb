class FbCred < ActiveRecord::Base

  belongs_to :user
  has_many :fb_pages, dependent: :destroy

  has_many :image_refs, as: :imageable
  has_many :images, through: :image_refs

  def self.from_omniauth(auth, id)
    begin
      where(user_id: id).first_or_initialize.tap do |fb_cred|
        fb_cred.u_id = auth.uid
        fb_cred.auth_token = auth.credentials.token
        fb_cred.email = auth.info.email
        fb_cred.name = auth.info.name        
        image_url = auth.info.image
        build_image(fb_cred, image_url)
        fb_cred.user_id = id
        fb_cred.time_zone = (User.find id).time_zone
        fb_cred.save
      end
      true
    rescue StandardError => err
      false
    end
  end

  def self.add_fb_user_from_massenger(page_id, new_user_id)
    begin
      page_access_token = (FbPage.find_by_page_id page_id)['page_access_token']
      user_data = FacebookMessengerService.get_user_info(page_access_token, new_user_id)
      full_name = user_data['first_name'] + ' ' + user_data['last_name']
      url = user_data['profile_pic']
      uid = new_user_id
      timezone = ActiveSupport::TimeZone.new(user_data['timezone']).tzinfo.name
      gender = user_data['gender']
      welcome_text = "Welcome #{name} to Rhombus-The Message Commerce platform"
      FacebookMessengerService.send_text_message(page_access_token, uid, welcome_text)
      fb_cred = FbCred.new(name: full_name, u_id: uid, time_zone: timezone, gender: gender)
      build_image(fb_cred, url)
      fb_cred.save   
    rescue StandardError => err
    end
  end

  private

  def self.process_uri(uri)
    require 'open-uri'
    require 'open_uri_redirections'
    open(uri, :allow_redirections => :safe) do |r|
      r.base_uri.to_s
    end
  end  

  def self.build_image(user, url)
    if url.present?
      avatar_url = process_uri(url)
      attachment_url = open(avatar_url)
      user.images.build(avatar: attachment_url)
    end
  end

end
