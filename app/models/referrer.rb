class Referrer < ActiveRecord::Base

  include Transactionable

  def get_referrer_link
    begin
      if ref = where(referrer_email: self.referrer_email).first
        self.uid = ref.referrer_uid
      else
        self.uid = generate_uid
        self.link = "dasd" #UrlShorternerService.shorten_link("https://www.getrhombus.com/signup?referrer_uid=#{self.uid}")
      end
      self.link
    rescue StandardError => e 
      nil
    end
  end

  def self.save_referrer_with_id(referrer, referee)
    ref = where(referrer_id: referrer, referee_id: referee).first
    self.update_attributes({ referrer_id: referrer, referee_id: referee }) if !ref
  end

  def self.save_referrer_with_uid(referrer, referee)
    ref = where(uid: referrer, referee_id: referee).first
    self.update_attributes({ uid: referrer, referee_id: referee }) if !ref
  end

end
