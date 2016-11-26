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
                        notEmpty: {
                            message: 'Subject is required'
                        }
                    }
                }
        }
    })
});
