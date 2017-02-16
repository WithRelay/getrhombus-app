class TransactionPresenter < BasePresenter
	def format_created_at
		time_ago = h.time_ago_in_words(@model.created_at).split(' ')
		time_number = time_ago.select{|t| t.to_i != 0}
		time_number = time_number.empty? ? [0] : time_number
    time_number.first + time_ago.last.first + ' ago'
  end
end
