$(document).ready(function() {
	$('#add_user_funds').formValidation({
    framework: 'bootstrap',
    live: 'disabled',

    // List of fields and their validation rules!
    fields: {
    	'user[account_balance]' :{
    		validators: {
    			integer: {
            message: 'The value is not an integer'
          }
    		}
    	}
    }
  })

})
