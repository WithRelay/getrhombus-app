class OpenCnamData < ActiveRecord::Base

  # save or update data in db
  def self.add_or_update_opencnam_data(phone_number, data)
    where(phone_number: phone_number).first_or_initialize.tap do |row|
      row.name = data[:name]
      row.price = data[:price].abs.to_s
      row.save
    end
  end

  def self.find_record_or_get_intelligence_data(phone_number)
  	unless where(phone_number: phone_number).exists?
  		GetIntelligenceDataJob.perform_later(phone_number, 'OpenCNAM')
  	end
  end

end