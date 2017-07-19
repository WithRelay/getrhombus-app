$(document).ready(function () {
  // validate notfications form
  $('#alert-form').formValidation({
    framework: 'bootstrap',
    excluded: ':disabled',
    live: 'disabled',
    // List of fields and their validation rules!
    fields: {
      'alert[emails]': {
        row: '.form-group',
        validators: {
          callback: {
            callback:function(value,validator, $field){
              debugger
              if($('#send-alert').is(':checked') && value == ''){
                return {
                  valid: false,
                  message: 'Add aleast one valid email'
                }
              }else{
                return {
                  valid: true
                }
              }
            }
          }
        }
      },
      'alert[sms_numbers]': {
        row: '.form-group',
        validators: {
          callback: {
            callback:function(value,validator, $field){
              if($('#send-alert').is(':checked') && $('#alert-include-sms').is(':checked') && $('#sms-alert') && value == ''){
                return {
                  valid: false,
                  message: 'Add aleast one valid number'
                }
              }else{
                return {
                  valid: true
                }
              }
            }
          }
        }
      }
    }
  });

  $('#alert-include-sms').change(function() {
    if (this.checked) {
      $('#alert-sms-number').slideDown(200);
    } else {
      $('#alert-sms-number').slideUp(200);
    };
  }).change();

  if ($('#alert_phone_numbers').length) {
    var $alert_phone_numbers_selectize = $('#alert_phone_numbers').selectize({
            plugins: ['remove_button'],
            options: [],
            labelField: 'number',
            valueField: 'number',
            create: false,
          })[0].selectize;
    var preset_numbers_data = $('#alert_phone_numbers').attr('data-numbers').trim();
    if (preset_numbers_data.length) {
      $.each(preset_numbers_data.split(','), function (index, number) {
        add_data_to_selectize($alert_phone_numbers_selectize, 'number', number);
      });
    };
  };

  if ($('#alert_emails').length) {
    var $alert_emails_selectize = $('#alert_emails').selectize({
              plugins: ['remove_button'],
              options: [],
              labelField: 'email',
              valueField: 'email',
              create: false,
            })[0].selectize;
    var preset_email_data = $('#alert_emails').attr('data-emails').trim();
    if (preset_numbers_data.length) {
      $.each(preset_email_data.split(','), function (index, email) {
        add_data_to_selectize($alert_emails_selectize, 'email', email)
      });
    };
  };

  $('#alerts-add-number').click(function() {
    $('#alert-form').formValidation('resetField', 'alert[sms_numbers]');
    set_button_status(this, true, 'Validating...');
    if (PhoneNumberFormatter.isValid()) {
      add_data_to_selectize($alert_phone_numbers_selectize, 'number', PhoneNumberFormatter.getNumber());
    } else {
      $('#phone').addClass('red-border');
    };
    set_button_status(this, false, 'Add number');
  });

  $('#alerts-add-email').click(function() {
    $('#alert-form').formValidation('resetField', 'alert[emails]');
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
        data.is_valid ? add_data_to_selectize($alert_emails_selectize, 'email', email) : show_email_invalid();
      },
      error: function(request, status_text, error) {
        add_data_to_selectize($alert_emails_selectize, 'email', email)
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

  function add_data_to_selectize(selectize_field, name, data) {
    var hash = {};
    hash[name] = data;
    selectize_field.addOption(hash);
    selectize_field.addItem(data);
  };

})
