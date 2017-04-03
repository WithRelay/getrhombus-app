class Referrer < ActiveRecord::Base

  include Transactionable
  has_many :notification_log, as: :notifiable, dependent: :destroy
  belongs_to :referrer, class_name: "User", foreign_key: :relay_uid
  belongs_to :referee, class_name: "User", foreign_key: :id
  attr_accessor :phone

  def self.save_referrer_with_uid(referrer, referee)
    ref = where(referrer_uid: referrer, referee_id: referee).first
    create(referrer_uid: referrer, referee_id: referee) unless ref
  end

  # we use this on Stripe's website or anywhere else necessary
  def self.create_stripe_default
    ref = create(referrer_email: '<redacted_email>', referrer_name: 'Stripe', uid: Transactionable.generate_uid)
    ref.update_attribute(:link, "https://www.getrhombus.com?referrer_uid=#{ref.uid}")
    #ref.update_attribute(:link, "https://www.relay.com?referrer_uid=#{ref.uid}")
  end

end
