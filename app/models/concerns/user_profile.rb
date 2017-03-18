module UserProfile
  extend ActiveSupport::Concern

  def get_conversation_display_name(uid, uid_type)
    if uid_type == "user"
      cus = User.find_by(id: uid)
      cus ? cus.full_name.present? ? cus.full_name : cus.email : "Relay user"
    else
      # does fb at least give us some info?
      uid_type == 'fb_page' ? "messenger user" : uid
    end
  end

  def get_user_snapshot(uid, uid_type, merchant_id)
    data = {}
    u = uid_type == 'user' ? find_by(id: uid) : nil
    data[:profile_picture] =  check_profile_picture(u)

    if uid_type == 'user' || uid_type == 'phone_number'
      x = TwilioNumberData.where(phone_number: u.phone_number).first
      data[:city] = x.present? ? x.city.titleize + " " + x.state : '-'
    else
      # fullcontact and fb_cred? combination
    end

    if uid_type == 'user'      
      data[:full_name] = u.full_name
      data[:phone_number] = u.is_merchant? ? u.org_phone : u.phone_number
      data[:email] = u.email
      x = MerchantCustomer.find_by(customer_id: uid, merchant_id: merchant_id)
      data[:since] = { date: x ? x.created_at.strftime('%m/%d/%Y') : '-', type: 'Customer' }
    else
      x = MerchantContact.find_by(uid: uid, uid_type: uid_type, merchant_id: merchant_id)
      data[:since] = { date: x ? x.created_at.strftime('%m/%d/%Y') : '-', type: 'Contact' }
    end

    # non user - use full contact
    # twitter handle - for user and (messenger only using fb_cred) through fullcontact data
    # email - messenger only using fb_cred
    # location - messenger only using fb_cred through full contact
    # phone - messenger only using fb_cred through full contact
    # name - phone number through opencnam or messenger using fb_cred through full contact
    # verified or no
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


end