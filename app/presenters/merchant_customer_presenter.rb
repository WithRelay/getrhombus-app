class MerchantCustomerPresenter < BasePresenter

  def profile_image(current_user)
    user = current_user.is_merchant? ? @model.customer : @model.merchant
    profile_pic = User.check_profile_picture(user)
    if profile_pic[:type] == "image"
      html = h.image_tag(profile_pic[:value], class: 'campaigns table-profile-picture', width: 24)
    elsif profile_pic[:type] == "color"
      class_name = " campaigns table-profile-picture radius-color-#{profile_pic[:value]}"
      html = ("<div class='"+ class_name +"'></div>").html_safe
    end
    html
  end

end
