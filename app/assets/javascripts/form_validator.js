$(document).ready(function() {
  $('#new_campaign').formValidation({
        framework: 'bootstrap',
        fields: {
            'campaign[name]': {
                validators: {
                    notEmpty: {
                        message: 'Campaign Name is required'
                    },
                    stringLength: {
                        message: 'Campaign Name should not be greater than 20 characters',
                        max: function (value, validator, $field) {
                            return 120 - (value.match(/\r/g) || []).length;
                        }
                    }
                }
            },
                'campaign[subject]': {
                  enable: $('#campaign_channel').val() == 3,
                    validators: {
                      callback: {
                            callback: function(value, validator, $field) {
                                return $('#campaign_channel').val() == 3
                            }
                        },
                        notEmpty: {
                            message: 'Subject is required'
                        }
                    }
                }
        }
    })
    .on('change', '[name="campaign[channel]"]', function(e) {
      if ($('#campaign_channel').val() == 3){
          $('#new_campaign').formValidation('revalidateField', 'campaign[subject]');
      }
      })
});
