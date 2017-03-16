$(document).ready(function() {
  $('#add_user_funds').formValidation({
    framework: 'bootstrap',
    live: 'disabled',

    // List of fields and their validation rules!
    fields: {
      'user[account_balance]' :{
        validators: {
          notEmpty: {
            message: 'Invalid'
          },
          regexp: {
            regexp: /^\s*(?=.*[1-9])\d*(?:\.\d{1,2})?\s*$/g,
            message: 'Invalid'
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
    $('.help-block').hide();
  });
})
