class TwilioNumberData < ActiveRecord::Base

  # save or update data in db
  def self.add_or_update_opencnam_data(phone, city, state, zip, country)
    where(phone_number: phone).first_or_initialize.tap do |row|
      row.city = city
      row.state = state
      row.zip = zip
      row.country = country
      row.save
    end
  end

end