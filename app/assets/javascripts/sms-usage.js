$(document).ready(function() {
  $('#add_user_funds').formValidation({
    framework: 'bootstrap',
    live: 'disabled',

    err: {
      container: '.messageContainer'
    },

    // List of fields and their validation rules!
    fields: {
      'user[recharge_amount]' :{
        validators: {
          notEmpty: {
            message: 'Invalid Amount'
          },
          regexp: {
            regexp: /^\s*(?=.*[1-9])\d*(?:\.\d{1,2})?\s*$/g,
            message: 'Invalid Amount'
          }
        }
      }
    }
  })
  .on('success.validator.fv', function(e, data) {
    data.element // Get the field element
    .removeClass('has-warning')
    .addClass('has-success')
  })
  .on('err.validator.fv', function(e) {
    // $('.help-block').hide();
  });

})
