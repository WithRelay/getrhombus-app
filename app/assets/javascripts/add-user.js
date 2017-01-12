$(document).ready(function() {
  var create_user_form = '#create-user-form',
      create_user_submit = '#create-user-submit';

  $('#select_user_country').selectize({
    closeAfterSelect: true,
  });

  $('#select-user-lists').selectize({
    valueField: 'id',
    labelField: 'name',
    searchField: 'name',
    create: false,
    options: [],
    closeAfterSelect: true,
    render: {
      item: function(item, escape) {
        return '<div> <span class="name">' + escape(item.name) + '</span></div>';
      }
    },
    load: function(query, callback) {
      if (!query.length) return callback();
      $.ajax({
        url: '/v1/lists.json?type=list',
        type: 'GET',
        dataType: 'json',
        data: {
          query: query
        },
        error: function() {
          FlashHandler.setFlashMessage('Something went wrong...Unable to find user lists', 'error');
          callback();
        },
        success: function(res) {
          callback(res['lists']);
        }
      });
    }
  });

  // form validation
  $(create_user_form).formValidation({
    framework: 'bootstrap',
    live: 'disabled',
    fields: {
      'user[email]': {
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
      'user_full_name': {
        validators: {
          notEmpty: {
            message: 'Full name is required '
          },
          regexp: {
            regexp: /^[a-z]([-']?[a-z]+)*( [a-z]([-']?[a-z]+)*)+$/,
            message: 'Full name can consists first and last name of alphabetical characters with spaces'
          }
        }
      },
      'user[phone]': {
        validators: {
          callback: {
            callback: function(value, validator, $field) {
              if (PhoneNumberFormatter.isValid()) {
                return {
                  valid: true, // or false
                  message: 'Valid number'
                }
              } else {
                return {
                  valid: false, // or false
                  message: 'Enter a valid number'
                }
              }
            }
          }
        }
      }
    }
  })
    .on('success.validator.fv', function(e, data) {
      if (data.field === 'user[email]' && data.validator === 'remote') {
        var response = data.result; // response is the result returned by MailGun API
        if (response.did_you_mean) {
          // Update the message
          data.element // The field element
            .data('fv.messages') // The message container
            .find('[data-fv-validator="remote"][data-fv-for="user[email]"]')
            .html('Did you mean ' + response.did_you_mean + '?')
            .show();
        }
      }
    })
    .on('err.validator.fv', function(e, data) {
      data.element
        .data('fv.messages')
        // Hide all the messages
        .find('.help-block[data-fv-for="' + data.field + '"]').hide()
        // Show only message associated with current validator
        .filter('[data-fv-validator="' + data.validator + '"]').show();
    })
    ///// add a customer
    .on('success.form.fv', function(e) {
      e.preventDefault();

      // if good above and card number is present, send card details to stripe
      if ($('#cc-number').val() == "") {
        $.each(["#cc-name", "#cc-exp", "#cc-csc"], function(index, val) { $(val).val(''); });
        submit_create_user_form();
      } else {
        CardHandler.submit_to_stripe(create_user_form, create_user_submit, submit_create_user_form);  
      }
    });

  function submit_create_user_form() {

    PhoneNumberFormatter.set_phone_number();
    UtilFunctions.set_first_and_last_names();

    $.ajax({
        url: "/v1/users/add_customers.json",
        beforeSend: function(xhr) {
          xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))
        },
        type: "POST",
        data: $(create_user_form).serialize(),
        dataType: "json"
      })
      .done(function(data, textStatus, jqXHR) {
        FlashHandler.setFlashMessage('Contacts created successfully', 'notice');
      })
      .fail(function(data, textStatus, errorThrown) {
        FlashHandler.setFlashMessage(JSON.parse(data.responseText).response, 'error');
      })
      .always(function(data, textStatus, response) {
        $(create_user_submit).attr("disabled", false).val('Create Customer');
      });
  }
  ///// add a customer

})
