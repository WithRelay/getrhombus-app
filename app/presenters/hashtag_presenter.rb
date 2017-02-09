class HashtagPresenter < BasePresenter
	
	TAG_TYPES = { non_payment_tag: 'Non-payment', one_time_payment_tag: 'One-time payment', recurring_payment_tag: 'Recurring payment'}.freeze

	def format_tag_type
		TAG_TYPES[:"#{@model.tag_type}"]
	end

	def get_submit_text
		@model.new_record? ? "Create Hashtag" : @model.active? ? 'Update Hashtag' : 'Resume Hashtag'
	end

	def get_tag_type_value
		Hashtag.tag_types[@model.tag_type]
	end

	def get_interval_string
		(@model.interval || '') + "_" + (@model.interval_count || '').to_s
	end

	def get_tag_type_options
		if @model.persisted? && @model.is_mentioned?
			opt = Hash.new
			opt[TAG_TYPES[@model.tag_type.to_sym] + ' Hashtag'] = get_tag_type_value 
			return opt
		end

		{ "Non-payment Hashtag" => "0", "One-time payment Hashtag" => '1', "Recurring payment Hashtag" => "2" }
	end

end