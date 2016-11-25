$(document).ready(function () {
  
  $('input#cc-number').payment('formatCardNumber');
  $('input#cc-exp').payment('formatCardExpiry');
  $('input#cc-csc').payment('formatCardCVC');

  var cc_form_btn = $('#cc-submit');

  // validate all credit card form
  cc_form_btn.click(function(){
    // get form id when submit button is clicked of credit card form
    var selector = $(this).parents('form:first').attr('id');
    validate_credit_card_form('#' + selector);
  });

  function validate_credit_card_form(form_selector) {
    $(form_selector).formValidation({
      // I am validating Bootstrap form
      framework: 'bootstrap',
      live: 'disabled',

      // List of fields and their validation rules
      fields: {
        'cc-name': {
          selector: '#cc-name',
          row: '.group',
          validators: {
            notEmpty: {
              message: 'Your card name is required'
            }
          }
        },
        'cc-number': {
          selector: '#cc-number',
          row: '.group',
          validators: {
            callback: {
              callback: function (value, validator, $field) {
                if ($.payment.validateCardNumber(value)) {
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
        },
        'cc-exp': {
          selector: '#cc-exp',
          row: '#exp-div',
          validators: {
            callback: {
              callback: function (value, validator, $field) {
                var y = CardHandler.get_expiry_date_data();
                if ($.payment.validateCardExpiry(y.month, y.year)) {
                  return {
                    valid: true,    // or false
                    message: 'Valid date'
                  }
                } else {
                  return {
                    valid: false,    // or false
                    message: 'Enter a valid date'
                  }
                }
              }
            }
          }
        },
        'cc-csc': {
          selector: '#cc-csc',
          row: '#csc-div',
          validators: {
            callback: {
              callback: function (value, validator, $field) {
                if ($.payment.validateCardCVC(value)) {
                  return {
                    valid: true,    // or false
                    message: 'Valid csc'
                  }
                } else {
                  return {
                    valid: false,    // or false
                    message: 'Enter a valid csc'
                  }
                }
              }
            }
          }
        }
      }
    })
    .on('err.field.fv', function(e, data) {
        // $(e.target)  --> The field element
        // data.fv      --> The FormValidation instance
        // data.field   --> The field name
        // data.element --> The field element

        // Hide the messages
        data.element
            .data('fv.messages')
            .find('.help-block[data-fv-for="' + data.field + '"]').hide();
    })
    .on('success.form.fv', function(e, data) {
      $(form_selector).bind("submit", preventDefault);
      CardHandler.submit_to_stripe(submit_cc_form, cc_form_btn)
    })
  }

  function submit_cc_form() {
    // credit card form id
    var form_id = $('#cc-submit').parents('form:first').attr('id');
    $("#" + form_id).unbind("submit", preventDefault).submit();
  }

  function preventDefault(e) { e.preventDefault(); }

  // Simply populates credit card and bank account fields with test data
  /*
    $('#populate').click(function () {
      $(this).attr("disabled", true);

      $('#cc-name').val('John Doe');
      $('#cc-number').val('<redacted_phone_number>');
      $('#cc-ex-month').val('12');
      $('#cc-ex-year').val('2020');
      $('#ex-csc').val('123');
    });
  */
});