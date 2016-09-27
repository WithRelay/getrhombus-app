class FbPage < ActiveRecord::Base
  belongs_to :user
  belongs_to :fb_cred
  has_many :fb_messages, dependent: :destroy

  def self.store_page(current_user)
    page_array = FacebookMessengerService.get_page(current_user.fb_cred.auth_token)
    page_array.each do |page|
      begin
        where(page_id: page["id"]).first_or_initialize.tap do |row|
          row.page_id = page["id"]
          row.user_id = current_user.id
          row.category = page["category"]
          row.page_access_token = page["access_token"]
          row.page_name = page["name"]
          row.fb_cred_id = current_user.fb_cred.id
          row.save
        end
      rescue StandardError => err
        nil
      end
    end
  end
end
