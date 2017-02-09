class HashtagPresenter < BasePresenter
	
	def format_tag_type
		tag_types = { non_payment_tag: 'Non-payment', one_time_payment_tag: 'One-time payment', recurring_payment_tag: 'Recurring payment'}
		tag_types[:"#{@model.tag_type}"]
	end
end