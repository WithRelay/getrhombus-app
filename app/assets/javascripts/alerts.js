$(document).ready(function () {

  // validate notfications form
  $('.edit_alert')
    .formValidation({
      framework: 'bootstrap',
      live: 'disabled',
      // List of fields and their validation rules!
      fields: {
        'alert[phone]': {
            row: '.form-group',
            validators: {
                callback: {
                    callback: function (value, validator, $field) {
                      if ($("#alert-include-sms").is(':checked')) {
                        if (PhoneNumberFormatter.isValid()) {
                            return {
                                valid: true,    // or false
                                message: 'Valid number'
                            }
                        } else {
                            return {
                                valid: false,    // or false
                                message: 'Enter a valid sms-enabled number.'
                            }
                        }
                      } else {
                        $("#phone_number").val('');
                        $("#phone").val('');
                        return { 
                            valid: true 
                        }
                      }
                    }
                }
            }
          }
      }
    })
    .on('success.form.fv', function(e, data) {
        var number = PhoneNumberFormatter.getNumber(); 
        $('#phone_number').val( (number.charAt(0) === "+") ? number.substring(1) : number );           
    });
        

})

                          