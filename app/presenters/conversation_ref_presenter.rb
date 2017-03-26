class ConversationRefPresenter < BasePresenter

  def format_textable_text
  	@model.textable ? @model.textable.text : ''
  end

  def format_resolution
  	# refactor this
  	@model.uid_conversation_resolution.resolution.present? ? 'Marked as Done' : 'Open'
  end

  def display_name
		User.get_conversation_display_name(@model.uid, @model.uid_type)   
  end

  def channel
  	if @model.textable_type == 'Message'
  		'SMS'
  	else @model.textable_type == 'FbMessage'
  		'Messenger'
  	end
  end

end