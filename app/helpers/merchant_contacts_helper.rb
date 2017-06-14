module MerchantContactsHelper
  def contact_or_customer
    params[:controller] == 'merchant_contacts' ? 'Contact' : 'Customer'
  end

  def profile_image_color(user_profile_data, need_campaign_class = false)
    profile_pic = user_profile_data[:profile_image]
    class_name = need_campaign_class ? 'campaigns table-profile-picture' : 'table-profile-picture'

    if profile_pic[:type] == "image"
      html = h.image_tag(profile_pic[:value], class: class_name, width: 24)
    elsif profile_pic[:type] == "color"
      class_name = class_name + " radius-color-#{profile_pic[:value]}"
      html = ("<div class='"+ class_name +"'></div>").html_safe
    end
    html
  end
end
