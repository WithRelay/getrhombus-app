class FbPage < ActiveRecord::Base
  belongs_to :user
  belongs_to :fb_cred

  def self.store_page(current_user)
    response = Koala::Facebook::API.new(current_user.fb_cred.auth_token)
    page_array = response.get_object('me/accounts/page')
    page_array.each do |page|
      begin
        where(page_id: page["id"]).first_or_initialize.tap do |row|
          row.page_id = page["id"]
          row.user_id = current_user.id
          row.category = page["category"]
          row.page_access_token = page["access_token"]
          row.page_name = page["name"] 
          row.save
        end
      rescue StandardError => err
      end
    end
  end
end
