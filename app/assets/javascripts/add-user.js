$(document).ready(function () {
  var create_user_form = '#create-user-form',
    create_user_submit = '#create-user-submit';

    $('#select_user_country').selectize({
        maxItems: 1,
        valueField: 'code',
        labelField: 'name',
        searchField: 'name',
        create: false,
        options: [],
        closeAfterSelect: true,
        load: function(query, callback) {
          if (!query.length) return callback();
          $.ajax({
            url: '/v1/countries/get_country_name/',
            type: 'GET',
            dataType: 'json',
            data: {
              name: query
            },
            error: function() {
              FlashHandler.setFlashMessage('Something went wrong...Unable to find your country name', 'error');
              callback();
            },
            success: function(res) {
              callback(res['countries']);
            }
          });
        }
      }).selectize();

    $('#select-user-lists').selectize({
       valueField: 'id',
        labelField: 'name',
        searchField: 'name',
        create: false,
        options: [],
        closeAfterSelect: true,
        load: function(query, callback) {
          if (!query.length) return callback();
          $.ajax({
            url: '/v1/lists/',
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
    }).selectize();

    // filter firstName and lastName from user_full_name
    $(create_user_submit).on('click', function(){
      var full_name = $('#user_full_name').val().split(' ');
      $('#firstName').val(full_name[0]);
      full_name.shift();
      $('#lastName').val(full_name.join(' '));
    });

    // form validation
    $('#create-user-form').formValidation({
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
      .on('success.validator.fv', function(e, data) {
          if (data.field === 'user[email]' && data.validator === 'remote') {
              var response = data.result;  // response is the result returned by MailGun API
              if (response.did_you_mean) {
                  // Update the message
                  data.element                    // The field element
                      .data('fv.messages')        // The message container
                      .find('[data-fv-validator="remote"][data-fv-for="user[email]"]')
                      .html('Did you mean ' + response.did_you_mean + '?')
                      .show();
              }
          }
      })
      .on('err.validator.fv', function(e, data) {
          if (data.field === 'user[email]' && data.validator === 'remote') {
              // We need to reset the error message
              data.element                // The field element
                  .data('fv.messages')    // The message container
                  .find('[data-fv-validator="remote"][data-fv-for="user[email]"]')
                  .html("The email isn't valid")
                  .show();
          }
      })
      ///// add a customer
      .on('success.form.fv', function(e){
        e.preventDefault();
        // run validations for email and phone number...have variable for fail
        // if good above and card number is present, send card details to stripe if...set fail variable
        // no validations for address or lists
        // if all pass, submit_contact_form

        var y = CardHandler.get_expiry_date_data();
        set_number();
        CardHandler.submit_to_stripe(create_user_form, create_user_submit, submit_create_user_form);

        // added accept nested attributes for lists
        // hashes of hashes or array of hashes for lists
        console.log($(this).serialize())
      });  

  function submit_create_user_form() {
    $.ajax({
        url: "/v1/users/add_customers.json",
        beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
        type: "POST",
        data: $(create_user_form).serialize(),
        dataType: "json"
    })
      .done(function(data, textStatus, jqXHR) {
        console.log(data);
      })
      .fail(function(data, textStatus, errorThrown) {
        console.log(data);
      })
      .always(function(data, textStatus, response) {
        cc_submit_btn.attr("disabled", false).val(cc_btn_text);
      });
  }
  ///// add a customer
  
})
