class TwitterCred < ActiveRecord::Base

  belongs_to :user

  # saves merchant twitter info
  def self.from_omniauth(auth, id)
    begin
      where(user_id: id).first_or_create do |row|
        row.uid = auth.uid
        row.token = auth.credentials.token
        row.secret = auth.credentials.secret
        
        row.nickname = auth.info.nickname
        row.name = auth.info.name
        row.location = auth.info.location
        row.description = auth.info.description

        row.url = auth.info.urls.Twitter
        row.website_url = auth.info.urls.Website

        row.followers_count = auth.extra.raw_info.followers_count
        row.friends_count = auth.extra.raw_info.friends_count
        row.image_url = auth.extra.raw_info.profile_image_url_https

        row.user_id = id
      end
      return true
    rescue StandardError => err
      false
    end
  end

end