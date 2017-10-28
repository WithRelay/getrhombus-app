class FbPage < ActiveRecord::Base
  belongs_to :user
  has_many :fb_messages, dependent: :destroy
  validates_presence_of :page_access_token
  scope :subscribed, -> { where(subscription_status: true) }
  scope :active, -> { where(active: true) }

  def self.store_page(current_user)
    original_fb_cred = current_user.fb_creds.original_cred.first
    page_array = FacebookMessengerService.get_page(original_fb_cred.auth_token)
    page_array.each do |page|
      begin
        where(page_id: page['id'], user_id: current_user.id).first_or_initialize.tap do |row|
          row.category = page['category']
          row.page_access_token = page['access_token']
          row.page_name = page['name']
          row.active = true
          row.save
        end
      rescue StandardError => err
        nil
      end
    end
  end

  def subscribe
    response = FacebookMessengerService.subscribe(page_access_token)
    return false unless response && response['success']
    update_attributes(subscription_status: true)
  end

  def unsubscribe
    response = FacebookMessengerService.unsubscribe(page_access_token)
    return false unless response && response['success']
    update_attributes(subscription_status: false)
  end

  def remove_or_inactivate_page
    if fb_messages.present?
      update_attributes(active: false)
    else
      destroy
    end
  end

  def subscribed_by_other_user?
    FbPage.where(page_id: self.page_id, subscription_status: true).where.not(user_id: self.user_id).present?
  end
end
