class ConversationRefPresenter < BasePresenter

  def format_textable_text
  	@model.textable ? @model.textable.text : ''
  end

  def format_resolution
  	@model.resolution.present? ? 'Marked as Done' : 'Open'
  end

  def display_name
	User.get_conversation_display_name(@model.uid, @model.uid_type)   
  end

end