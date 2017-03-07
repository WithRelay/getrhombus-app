class ConversationRefPresenter < BasePresenter

  def format_textable_text
  	@model.textable ? @model.textable.text : ''
  end

  def format_resolution
  	@model.resolution.present? ? 'Marked as Done' : 'Open'
  end

end