# image presenter for image object
class ImagePresenter < BasePresenter

  def image_url
    h.image_tag @model.avatar.url if avatar_present?
  end

  def image_delete_url
    h.link_to 'Delete Image', '#', class: 'delete-image', id: "image_#{@model.id}" if avatar_present?
  end

  def avatar_present?
    @model.avatar.present?
  end
end
