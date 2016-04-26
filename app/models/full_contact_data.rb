class FullContactData < ActiveRecord::Base

  has_many :full_contact_social_datas, dependent: :destroy

  def self.add_or_update_fullcontact_data(email, person)
    begin
      row = where(email: email).first_or_initialize
      row.likelihood = person.likelihood

      d = person.contact_info
      if d
        row.given_name =  d.given_name
        row.family_name = d.family_name
        row.website_url = (d.websites) ? d.websites[0].url : nil
      end

      d = person.demographics
      if d
        row.age_range = d.age_range
        row.gender = d.gender
        d = d.location_deduced
        row.city = (d && d.city) ? d.city.name : nil
        row.country = (d && d.country) ? d.country.code : nil
      end

      d = person.photos
      if d
        row.photo_url = d[0].type_id
        row.photo_type_id = d[0].url
        d.each do |p|
          if p.is_primary == true
            row.photo_url = p.type_id
            row.photo_type_id = p.url
            break
          end
        end
      end

      d = person.organizations
      if d
        row.org_name = d[0].name
        row.org_title = d[0].title
        d.each do |o|
          if o.current == true || o.is_primary == true
            row.org_name = o.name
            row.org_title = o.title
            break
          end
        end
      end   
      
      row.save

      d = person.social_profiles
      FullContactSocialData.add_or_update_fullcontact_social_data(row.id, d) if d
    rescue StandardError => err
      false
    end
  end

  # wrap this up and test model and service when integrating front end
  def self.get_fullcontact_data(email)
  end

end