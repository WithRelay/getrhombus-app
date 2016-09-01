module ApplicationHelper

  def generate_image_thumbnails(images)
    div = ""
    images.each do |i|
      div += "<div class='images'>" +
        '<span class="delete-image" id="img_"' + i.id.to_s + '">X</span> <br>' +
        '<img src="' + i.avatar.url + '" width="100" height="100" />' +
        "<span>" + i.avatar_file_name + "</span>" +
        "</div>"
    end
    div.html_safe
  end

end
