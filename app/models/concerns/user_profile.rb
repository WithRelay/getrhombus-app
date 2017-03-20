module UserProfile
  extend ActiveSupport::Concern

  include PrettyDate

  def get_conversation_display_name(uid, uid_type)
    if uid_type == "user"
      cus = User.find_by(id: uid)
      cus ? cus.full_name.present? ? cus.full_name : cus.email : "Relay User"
    else
      if uid_type == "fb_page"
        cus = FbCred.find_by(page_specific_id: uid)
        return cus.name if cus && cus.name.present?
        return cus.email if cus && cus.email.present?
        'Messenger Contact'
      else
        cus = OpenCnamData.find_by(phone_number: uid)
        return cus.name if cus && cus.name.present?
        'SMS Contact'
      end
    end
  end

  def check_profile_picture(cus)
    return { type: 'color', value: COLORS.first.first } if cus.nil?

    user_fb_cred = cus.fb_creds
    if user_fb_cred.present? && user_fb_cred.first.profile_pic_url.present?
      return { type:'image', value: user_fb_cred.first.profile_pic_url }
    end

    contact_email = FullContactData.find_by_email(cus.email)
    if contact_email && contact_email.photo_url.present?
      return { type: 'image', value: contact_email.photo_url }
    elsif cus.user_color.blank?
      cus.update(user_color: COLORS.sample.first)
    end
    { type: 'color', value: cus.user_color }
  end

  # 8 data points
  def get_user_snapshot(uid, uid_type, merchant_id)
    data = {}
    u = User.find_by(id: uid) if uid_type == 'user' 
    
    # 1 & 2
    data[:verified] = (u && uid_type == 'user') ? 'VERIFIED' : 'UNVERIFIED'
    data[:profile_image] = check_profile_picture(u)

    # 6 more data points
    if uid_type == 'user'      
      
      data[:full_name] = get_conversation_display_name(uid, uid_type)
      data[:phone_number] = u ? u.is_merchant? ? u.org_phone : u.phone_number : '-'
      data[:email] = u ? u.email : '-'

      x = MerchantCustomer.find_by(customer_id: uid, merchant_id: merchant_id)
      data[:since] = { date: '-', relative: '-' , type: 'Customer'}
      data[:since] = { date: x.created_at.strftime('%m/%d/%Y'), relative: time_in_relative_form(x.created_at, 'long_format'), type: 'Customer'} if x && x.created_at.present? 
      
      data[:location] = get_user_location(uid, uid_type)
      
      x = FullContactData.find_by(email: data[:email])
      x = x.full_contact_social_datas.find_by(type_id: 'twitter') if x.present?
      data[:twitter] = x.present? && x.username.present? ? x.username : '-'

    elsif uid_type == 'phone_number'
      
      data[:full_name] = get_conversation_display_name(uid, uid_type)
      data[:phone_number] = uid
      data[:email] = '-'

      x = MerchantContact.find_by(uid: uid, merchant_id: merchant_id, uid_type: uid_type)
      data[:since] = { date: '-', relative: '-' , type: 'Contact'}
      data[:since] = { date: x.created_at.strftime('%m/%d/%Y'), relative: time_in_relative_form(x.created_at, 'long_format'), type: 'Contact'} if x && x.created_at.present? 
      
      x = TwilioNumberData.find_by(phone_number: uid)
      data[:location] = get_user_location(uid, uid_type)
      
      data[:twitter] = '-'

    elsif uid_type == 'fb_page'
         
      data[:full_name] = get_conversation_display_name(uid, uid_type)
      data[:phone_number] = '-'
      x = FbCred.find_by(page_specific_id: uid)   
      data[:email] = x.present? && x.email.present? ? x.email : '-'

      x = MerchantContact.find_by(uid: uid, merchant_id: merchant_id, uid_type: uid_type)
      data[:since] = { date: '-', relative: '-' , type: 'Contact'}
      data[:since] = { date: x.created_at.strftime('%m/%d/%Y'), relative: time_in_relative_form(x.created_at, 'long_format'), type: 'Contact'} if x && x.created_at.present? 
      
      if data[:email] != '-'
        x = FullContactData.find_by(email: data[:email])
        data[:location] = x.present? && x.city.present? ? x.city : '-'  
        x = x.full_contact_social_datas.find_by(type_id: 'twitter') if x.present?
      end

      data[:twitter] = data[:email] != "-" && x.present? && x.username.present? ? x.username : '-'
      
    end

    data
  end

end