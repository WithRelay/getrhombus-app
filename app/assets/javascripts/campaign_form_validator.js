$(document).ready(function() {
  $('#new_campaign').formValidation({
    framework: 'bootstrap',
    live: 'disabled',
    excluded: [ ':hidden', ':not(:visible)' ],
    fields: {
      'campaign[name]': {
        validators: {
          notEmpty: {
              message: 'Campaign Name is required'
          }
        }
      },
        'campaign[subject]': {
          enable: $('#campaign_channel').val() == 3,
          validators: {
            notEmpty: {
                message: 'Subject is required'
            }
          }
        }
    }
  })
});
