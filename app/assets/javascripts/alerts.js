$(document).ready(function () {
  // validate notfications form
  /*$('#alert-form')
    .formValidation({
      framework: 'bootstrap',
      live: 'disabled',
      // List of fields and their validation rules!
      fields: {
        'alert[sms_numbers]': {
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
        },
        'alert[emails]': {
          row: '.form-group',
          validators: {
            callback: {
              callback: function (value, validator, $field) {
              }
            }
          }
        }
      }
    })
    .on('success.form.fv', function(e, data) {
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
    set_button_status(this, true, 'Validating...');
    if (PhoneNumberFormatter.isValid()) {
      var number = PhoneNumberFormatter.getNumber();
      $alert_phone_numbers_selectize.addOption({ number: number  });
      $alert_phone_numbers_selectize.addItem(number);
    } else {
      $('#phone').addClass('red-border');
    };
    set_button_status(this, false, 'Add number');
  });

  $('#alerts-add-email').click(function() {
    set_button_status(this, true, 'Validating...');
    var email = $('#alerts-enter-email').val().trim();
    
    if (!email.length) {
      show_email_invalid();
      set_button_status(this, false, 'Add Email');
      return;
    };

    var $this = this;
    $.ajax({
      type: "GET",
      url: 'https://api.mailgun.net/v3/address/validate',
      data: { address: email, api_key: '<redacted_api_key>' },
      dataType: "jsonp",
      crossDomain: true,
      success: function(data, status_text) {
        data.is_valid ? add_email_to_selectize_emails(email) : show_email_invalid();
      },
      error: function(request, status_text, error) {
        add_email_to_selectize_emails(email);
      },
      complete: function() {
        set_button_status($this, false, 'Add Email');
      },
      timeout: 6000
    });
  });

  $('#alerts-enter-email').on('focus', function() {
    $(this).removeClass('red-border');
    $("#alerts-email-validation-message").hide();
  });

  function show_email_invalid() {
    $('#alerts-enter-email').addClass('red-border');
    $("#alerts-email-validation-message").show();
  };

  function set_button_status(btn, disabled, text) {
    btn.disabled = disabled;
    btn.textContent = text;
  };

  function add_email_to_selectize_emails(email) {
    $alert_emails_selectize.addOption({email: email});
    $alert_emails_selectize.addItem(email);
  };
  
  var preset_data = $('#alert_emails').attr('data-numbers');
  if (UtilFunctions.is_present(preset_data)) {
    $.each(preset_data, function (index, val) {
      $alert_phone_numbers_selectize.addOption({ number: val  });
      $alert_phone_numbers_selectize.addItem(val);
    });  
  };
  
  preset_data = $('#alert_emails').attr('data-emails');
  if (UtilFunctions.is_present(preset_data)) {
    $.each(preset_data, function (index, val) {
      $alert_phone_numbers_selectize.addOption({ email: val  });
      $alert_phone_numbers_selectize.addItem(val);
    });
  };
})
