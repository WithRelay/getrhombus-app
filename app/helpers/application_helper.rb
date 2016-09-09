module ApplicationHelper

  def generate_image_thumbnails(images)
    div = ""
    if images.present?
      images.each do |i|
        div += "<div class='images'>" +
          '<span class="delete-image" id="img_"' + i.id.to_s + '">X</span> <br>' +
          '<img src="' + i.avatar.url + '" width="100" height="100" />' +
          "<span>" + i.avatar_file_name + "</span>" +
          "</div>"
      end
    end
    div.html_safe
  end

  def present(model, presenter_class=nil)
    klass = presenter_class || "#{model.class}Presenter".constantize
    presenter = klass.new(model, self, current_user)
    if block_given?
      yield(presenter)
    else
      presenter
    end
  end



end
