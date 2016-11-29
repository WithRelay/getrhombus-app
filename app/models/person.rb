class Person < ActiveRecord::Base

  attr_accessor :full_name
  has_one :address, as: :addressable, dependent: :destroy
  belongs_to :user
  accepts_nested_attributes_for :address#, reject_if: :all_blank
  before_validation :the_titleizer  

  enum role: { representative: 0, owner: 1 }


  def full_name=(val)
    n = val.split(" ", 2)
    write_attribute(:first_name, n[0])
    write_attribute(:last_name, n[1] || "")
  end

  def full_name
    x = self.first_name || ''
    y = self.last_name || ''
    (x + y) == "" ? nil : x + " " + y
  end

  private

    def the_titleizer       #remove leading and trailing whitespaces
      self.first_name = self.first_name.strip.titleize unless self.first_name.blank?
      self.last_name = self.last_name.strip.titleize unless self.last_name.blank?
    end

  
end
