module MerchantContactsHelper
  def contact_or_customer
    params[:controller] == 'merchant_contacts' ? 'Contact' : 'Customer'
  end

  def profile_image_color(user_profile_data)
    profile_pic = user_profile_data[:profile_image]
    if profile_pic[:type] == "image"
          html = h.image_tag(profile_pic[:value], class: 'table-profile-picture', width: 24)
          html = h.image_tag(profile_pic[:value], class: 'campaigns table-profile-picture', width: 24) if need_campaign_class?
    elsif profile_pic[:type] == "color"
      class_name_value = "table-profile-picture radius-color-#{profile_pic[:value]}"
      class_name = ['Reminder', 'Transaction'].include?(@model.class.to_s) ? class_name_value : "campaigns #{class_name_value}"
      html = ("<div class='"+class_name+"'></div>").html_safe
    end
    html
  end
end
