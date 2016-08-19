class OpenCnamData < ActiveRecord::Base

  # save or update data in db
  def self.add_or_update_opencnam_data(phone, data)
    where(phone_number: phone).first_or_initialize.tap do |row|
      row.name = data[:name]
      row.price = data[:price].abs.to_s
      row.save
    end
  end

  # wrap this up and test model and service when integrating front end
  def self.get_opecnam_data(phone)
  end

end