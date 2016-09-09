class HashtagPresenter < BasePresenter

  def images
    return @model.images if @model.images.present?
    []
  end

end