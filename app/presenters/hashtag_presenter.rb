class HashtagPresenter < BasePresenter

  def images
    return [] if @model.images.empty?
    @model.images
  end

end