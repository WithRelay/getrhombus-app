# image presenter for image object
class ImagePresenter < BasePresenter

  def image_url
    h.image_tag(@model.avatar.url, class: 'editor-thumbnail') if avatar_present?
  end

  def image_delete_url                   
    if avatar_present?
    	h.div_for(@model, class: 'deleteImagePreview', id: "image_#{@model.id}") do
    		"x"
    	end
    end
  end

  def image_name
  	if avatar_present?
    	h.div_for(@model, class: 'editor-file-name shrink-text', id: "image_#{@model.id}") do
    		@model.avatar.original_filename
    	end
    end
  end

  def avatar_present?
    @model.avatar.present?
  end
end
