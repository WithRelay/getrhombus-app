class Address < ActiveRecord::Base

  belongs_to :addressable, :polymorphic => true
  before_validation :the_titleizer  
  validates :country, length: { is: 2 }, allow_blank: true   # mostly for csv upload

  private
    
    def the_titleizer       #remove leading and trailing whitespaces
      self.street_address = self.street_address.strip unless self.street_address.blank?
      self.city = self.city.strip.titleize unless self.city.blank?
      self.country = self.country.strip.upcase unless self.country.blank?
      self.state_province = self.state_province.strip.upcase unless self.state_province.blank?
      self.postal_code = self.postal_code.strip.upcase unless self.postal_code.blank?      
    end


end
