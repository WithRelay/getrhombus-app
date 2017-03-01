module CustomerListsHelper
	def customer_list_field(f)
		if(controller.action_name == 'show' && controller.controller_name == "merchant_customers")
	    f.hidden_field :customer_lists, value: @customer_id 
	   else
	    f.text_field :customer_lists, class: 'search-customers-and-contacts text-field w-input', id: 'reminder-customer-list'
		end
	end
end
