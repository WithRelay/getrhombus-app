class ConversationPresenter < BasePresenter
	
  def get_full_name
    User.get_display_name(@model.uid, @model.uid_type)
  end

end
