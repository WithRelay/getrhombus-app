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
                        $("#phone_number, #phone").val('');
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
      UtilFunctions.set_phone_number();
    });

  $('#alert-include-sms').change(function() {
    if (this.checked) {
      $('#alert-sms-number').slideDown(200);
    } else {
      $('#alert-sms-number').slideUp(200);
      $('.edit_alert').data('formValidation').resetForm();
    }
  }).change();

  $('.country-list').click(function() {
    if ($("#alert-include-sms").is(':checked') && $("#phone").val() != "") {
      $('.edit_alert').formValidation('revalidateField', "alert[phone]");
    }
  });


})

                          