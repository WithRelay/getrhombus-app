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
end
