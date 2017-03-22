module MerchantContactsHelper
   def profile_image(profile_pic)
     if profile_pic[:type] == "image"
       html = h.image_tag(profile_pic[:value], class: 'table-profile-picture', width: 24)
     elsif profile_pic[:type] == "color"
       class_name = "table-profile-picture radius-color-#{profile_pic[:value]}"
       html = ("<div class='"+ class_name +"'></div>").html_safe
     end
     html
   end
end
