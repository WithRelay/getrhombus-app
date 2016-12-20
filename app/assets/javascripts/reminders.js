$(document).on('ready page:load', function() {
  $('#new_reminder').formValidation({
    framework: 'bootstrap',
    excluded: ':disabled',
    live: 'disabled',
    fields: {
      'reminder[channel]': {
        validators: {
          notEmpty: {
            message: 'Campaign name is required'
          }
        }
      },
      'reminder[text]': {
        validators: {
          notEmpty: {
            message: 'This Field is required'
          }
        }
      },
      'reminder[date_time]': {
        validators: {
          callback: {
            message: 'Date and Time should be 30 minutes greate than current date time',
            callback: function(value, validator, $field) {
              var selectedDateTime = $('#new_reminder').find('[name="reminder[date_time]"]').val();
              var momentDate = moment(selectedDateTime).toDate()
              var userDateTime = new Date(new Date().getTime() + 30*60000)
              return userDateTime < momentDate
            }
          }
        }
      }
    }
  }).on('change', function(e) {
    $('#new_reminder').formValidation('resetField', 'reminder[date_time]');
  });
});
