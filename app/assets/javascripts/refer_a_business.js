$(document).ready(function () {

  $('#referrer_country').selectize({
    closeAfterSelect: true,
  });

  // validate coupon form
  $('#referrerForm')
    .formValidation({
      framework: 'bootstrap',
      live: 'disabled',
      // List of fields and their validation rules
      fields: {
          'referrer[referrer_name]': {
              validators: {
                notEmpty: {
                      message: 'Name is required'
                }
              }
          },
          'referrer[org_name]': {
              validators: {
                notEmpty: {
                      message: 'Business name is required'
                }
              }
          },
          'referrer[country]': {
              validators: {
                notEmpty: {
                      message: 'Country name is required'
                }
              }
          },
          'referrer[referrer_email]': {
              verbose: false,
              validators: {
                  notEmpty: {
                      message: 'Your email is required'
                  },
                  emailAddress: {
                      message: "The email isn't valid"
                  },
                  remote: {
                      type: 'GET',
                      url: 'https://api.mailgun.net/v2/address/validate?callback=?',
                      crossDomain: true,
                      name: 'address',
                      data: {
                        // Registry a Mailgun account and get a free API key
                        // at https://mailgun.com/signup
                        api_key: '<redacted_api_key>'
                      },
                      dataType: 'jsonp',
                      validKey: 'is_valid',
                      message: "The email isn't valid"
                  }
              }
          },
          'referrer[referee_email]': {
              verbose: false,
              validators: {
                  notEmpty: {
                      message: 'Your email is required'
                  },
                  emailAddress: {
                      message: "The email isn't valid"
                  },
                  remote: {
                      type: 'GET',
                      url: 'https://api.mailgun.net/v2/address/validate?callback=?',
                      crossDomain: true,
                      name: 'address',
                      data: {
                        // Registry a Mailgun account and get a free API key
                        // at https://mailgun.com/signup
                        api_key: '<redacted_api_key>'
                      },
                      dataType: 'jsonp',
                      validKey: 'is_valid',
                      message: "The email isn't valid"
                  }
              }
          },
          'referrer[phone]': {
              validators: {
                  callback: {
                      callback: function (value, validator, $field) {
                          if (value && PhoneNumberFormatter.isValid()) {
                              return {
                                  valid: true,    // or false
                                  message: 'Valid number'
                              }
                          } else {
                              return {
                                  valid: false,    // or false
                                  message: 'Enter a valid number'
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
    if ($(this).attr('action').split('/').pop() !== 'refer_business') {
      e.preventDefault();
      $("#referrer-submit").attr("disabled", true).val("Please wait...");
      referBusiness();
    }
  })
  .on('submit.form.fv', function(e,data) {
    if ($( "input[name='referrer[phone]']" ).val() === '') {
      $('#referrerForm').formValidation('resetField', 'referrer[phone]');
    }
  })
  .on('err.validator.fv', function(e) {
    $('.help-block').hide();
  });

  function referBusiness() {
    $.ajax({
       url: "/v1/referrers/invite_business.json",
       beforeSend: function(xhr) {
         xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))
       },
       type: "POST",
       data: $('#referrerForm').serialize(),
       dataType: "json"
     })
     .done(function(data, textStatus, jqXHR) {
       FlashHandler.setFlashMessage(data.response, 'notice');
     })
     .fail(function(data, textStatus, errorThrown) {
       FlashHandler.setFlashMessage(JSON.parse(data.responseText).response, 'error');
     })
     .always(function(data, textStatus, response) {
       $('#referrer-submit').removeAttr('disabled').val("Invite business");
     });
  };

})
