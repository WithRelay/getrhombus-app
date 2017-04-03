class Referrer < ActiveRecord::Base

  include Transactionable
  has_many :notification_log, as: :notifiable, dependent: :destroy
  belongs_to :referrer, class_name: "User"
  belongs_to :referee, class_name: "User"


  def get_referrer_link
    begin
      if ref = where(referrer_email: self.referrer_email).first
        self.uid = ref.referrer_uid
      else
        self.uid = generate_uid
        self.link = "dasd" #UrlShorternerService.shorten_link("https://www.withrelay.com/signup?referrer_uid=#{self.uid}")
      end
      self.link
    rescue StandardError => e 
      nil
    end
  end

  def self.save_referrer_with_id(referrer, referee)
    ref = where(referrer_id: referrer, referee_id: referee).first
    create(referrer_id: referrer, referee_id: referee) unless ref
  end

  def self.save_referrer_with_uid(referrer, referee)
    ref = where(uid: referrer, referee_id: referee).first
    create(uid: referrer, referee_id: referee) unless ref
  end

  # we use this on Stripe's website or anywhere else necessary
  def self.create_stripe_default
    ref = create(referrer_email: '<redacted_email>', referrer_name: 'Stripe', uid: Transactionable.generate_uid)
    ref.update_attribute(:link, "https://www.getrhombus.com?referrer_uid=#{ref.uid}")
    #ref.update_attribute(:link, "https://www.relay.com?referrer_uid=#{ref.uid}")
  end

end
