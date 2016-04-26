class FullContactSocialData < ActiveRecord::Base

  belongs_to :full_contact_data


  def self.add_or_update_fullcontact_social_data(id, social_data)
    begin
      social_data.each do |s|
        ## add a compound index here and make it unique...though not sure fullcontact wont return two same type_ids
        # This ensures that for each contact info, unique social profiles are saved even if fullcontact returns same type_ids
        where(full_contact_data_id: id, type_id: s.type_id).first_or_create do |row|
          row.followers = s.followers
          row.type_id = s.type_id
          row.url = s.url
          row.following = s.following 
          row.full_contact_data_id = id
        end
      end
    rescue StandardError => err
      false
    end
  end

end