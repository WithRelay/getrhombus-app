$(document).ready(function() {
  $('#new_campaign').formValidation({
    framework: 'bootstrap',
    live: 'disabled',
    excluded: [ ':hidden', ':not(:visible)' ],
    fields: {
      'campaign[name]': {
          validators: {
            notEmpty: {
                  message: 'Campaign name is required'
            },
            remote: {
                message: 'Campaign name already taken.',
                url: '/v1/campaigns/check_campaign_name',
                type: 'POST'
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
