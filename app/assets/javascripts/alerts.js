$(document).ready(function () {
  // validate notfications form
  /*$('#alert-form')
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
      PhoneNumberFormatter.set_phone_number();
    });*/

  $('#alert-include-sms').change(function() {
    if (this.checked) {
      $('#alert-sms-number').slideDown(200);
    } else {
      $('#alert-sms-number').slideUp(200);
    };
  }).change();

  var $alert_phone_numbers_selectize = $('#alert_phone_numbers').selectize({
            plugins: ['remove_button'],
            options: [],
            labelField: 'number',
            valueField: 'number',
            create: false,
          })[0].selectize;

  var $alert_emails_selectize = $('#alert_emails').selectize({
              plugins: ['remove_button'],
              options: [],
              labelField: 'email',
              valueField: 'email',
              create: false,
            })[0].selectize;

  $('#alerts-add-number').click(function() {
    if (PhoneNumberFormatter.isValid()) {
      var number = PhoneNumberFormatter.getNumber();
      $alert_phone_numbers_selectize.addOption({ number: number  });
      $alert_phone_numbers_selectize.addItem(number);
    } else {
      $('#phone').addClass('red-border');
    }
  });

  $('#alerts-add-email').click(function() {
    console.log('ads')
    $('#alerts-enter-email').mailgun_validator({
       api_key: '<redacted_api_key>',
       success: function(data) {
        console.log(data)
       },
       error: function(data) {
        console.log(data)
       }
    });
    /*var email = $('#email').val();
     $alert_emails_selectize.addOption({email: email});
     $alert_emails_selectize.addItem(email);*/
  });


})
