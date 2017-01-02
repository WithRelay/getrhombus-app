class FbPage < ActiveRecord::Base
  belongs_to :user
  has_many :fb_messages, dependent: :destroy
  validates_presence_of :page_access_token
  scope :subscribed, -> { where(subscription_status: true) }

  def self.store_page(current_user)
    original_fb_cred = current_user.fb_creds.original_cred.first
    page_array = FacebookMessengerService.get_page(original_fb_cred.auth_token)
    page_array.each do |page|
      begin
        where(page_id: page["id"]).first_or_initialize.tap do |row|
          row.user_id = current_user.id
          row.category = page["category"]
          row.page_access_token = page["access_token"]
          row.page_name = page["name"]
          row.save
        end
      rescue StandardError => err
        nil
      end
    end
  end

end
