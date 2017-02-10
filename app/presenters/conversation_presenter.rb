class ConversationPresenter < BasePresenter

  def get_full_name
    Conversation.get_display_name(@model.uid, @model.uid_type)
  end

  def conversation_channel
    channel = { 'fb_page'=> 'messenger', 'phone_number'=> 'Phone' }
    return if channel[@model.uid_type].present?
    return @model.last.conversation_refs.textable_type
  end
end
