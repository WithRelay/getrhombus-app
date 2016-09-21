class FbCred < ActiveRecord::Base

  belongs_to :user

  def self.from_omniauth(auth, id)
    begin
      where(id: id).first_or_initialize.tap do |user|
        user.u_id = auth.uid
        user.auth_token = auth.credentials.token
        user.email = auth.info.email
        user.name = auth.info.name        
        user.image_url = auth.info.image
        user.id = id
        user.save
      end
      true
    rescue StandardError => err
      false
    end
  end
end
