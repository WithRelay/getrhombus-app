$(document).ready(function () {
  var url = window.location,
    global_page_params = PageParameter.get_params();
  // to prefill signup form or handle captured payments
  // signin is included for when user texts payment and is prompted to sign in to complete account
  // can use form presence instead

  $('#get-started-form').formValidation({
          // I am validating Bootstrap form
          framework: 'bootstrap',
          live: 'disabled',

          // List of fields and their validation rules!
          fields: {
              'user[email]': {
                  verbose: false,
                  row: '.group',
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
              'user[phone]': {
                  row: '.group',
                  validators: {
                      callback: {
                          callback: function (value, validator, $field) {
                              if (PhoneNumberFormatter.isValid()) {
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
        UtilFunctions.set_phone_number();
      });

  if (["/signup", "/signin", "/users/sign_in", '/users', "/profile"].indexOf(url.pathname) != -1) {
      var amt = validate_captured_amt(global_page_params['amt']);
      if (global_page_params['user[check]'] && url.pathname == "/signup") {
        $('#email').val(global_page_params['user[email]']);
        $('#phone').attr('value', global_page_params['user[phone]']);
      } else if (url.pathname == "/signup") {
          $('#phone').val(global_page_params['num']);
          hide_account_type(global_page_params['referrer']);
      } else if (url.pathname == "/profile" && amt) {
          cc_submit.prop('value', 'Save & Pay ' + (amt/100));   // on profile page show the amt in button
      } else if (url.pathname == '/users') {
          hide_account_type(document.getElementById('referrer').value);
      }

      if (amt) document.getElementById('captured_amt').value = amt;
  }
  // to prefill signup form or handle captured payments

  function hide_account_type(referrer) {
      if (referrer) {
          $('#signupForm .selectpicker').val('0');
          $('#signupForm .accountTypegroup').hide();
          $("#signup_logo").replaceWith("<h2 class='referrer'>" + referrer + "</h2>");
          $("#rhombusPower").removeClass('hide');
      } else {
          $("#rhombusPower").addClass('hide');
      }
  }

  function validate_captured_amt(str) {
    if (str.match(/^\d+$/)) {
      str = parseInt(str);
      if (str < 1500000) return str;
    }
    return false;
  }
})
