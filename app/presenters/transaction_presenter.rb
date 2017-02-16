class TransactionPresenter < BasePresenter
	def format_created_at
		time_ago = h.time_ago_in_words(@model.created_at).split(' ')

    time_ago.first + time_ago.last.first + ' ago'
  end
end
