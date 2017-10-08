class Referrer < ActiveRecord::Base
  belongs_to :referrer, class_name: 'User', foreign_key: :relay_uid
  belongs_to :referee, class_name: 'User', foreign_key: :id
  attr_accessor :phone

  def self.save_referrer_with_uid(referrer, referee)
    ref = where(referrer_uid: referrer, referee_id: referee).first
    create(referrer_uid: referrer, referee_id: referee) unless ref
  end

end
