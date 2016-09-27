class FbCred < ActiveRecord::Base

  belongs_to :user
  has_many :fb_pages

  def self.from_omniauth(auth, id)
    begin
      where(user_id: id).first_or_initialize.tap do |user|
        user.u_id = auth.uid
        user.auth_token = auth.credentials.token
        user.email = auth.info.email
        user.name = auth.info.name        
        user.image_url = auth.info.image
        user.user_id = id
        user.save
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
      name = user_data['first_name'] + ' ' + user_data['last_name']
      url = user_data['profile_pic']
      uid = new_user_id
      FbCred.create(name: name, image_url: url, u_id: uid)
    rescue StandardError => err
    end
  end

end
