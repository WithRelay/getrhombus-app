$(document).ready(function() {
  function create_rule(formData) {
    $.ajax({
      url: window.location.origin + '/v1/rules',
      method: 'POST',
      data: formData,
      dataType: 'json'
    })
      .done(function(res) {
        FlashHandler.setFlashMessage(res.notice, 'notice');
        location.reload();
      })
      .error(function(res) {
        FlashHandler.setFlashMessage(res.error, 'error');
      });
  }

  if ($('#rule-form').length > 0) {
    $('#rule-form')
      .formValidation({
        framework: 'bootstrap',
        live: 'disabled',
        err: {
          container: function($field, validator) {
            return $field.parent().find('.messageContainer');
          }
        },
        fields: {
          'rule[text]': {
            validators: {
              notEmpty: {
                message: 'This field is required'
              }
            }
          },
          'rule[response]': {
            validators: {
              notEmpty: {
                message: 'This field is required'
              }
            }
          },
          'rule[message_length]': {
            verbose: false,
            selector: '#message-length',
            validators: {
              notEmpty: {
                message: 'Message length is required'
              },
              regexp: {
                regexp: /^\d+$/,
                message: 'Invalid Message Length'
              }
            }
          }
        }
      })
      .on('success.form.fv', function(e, data) {
        e.preventDefault();
        create_rule($(this).serialize());
      });
  }

  $('#rule-type').on('change', function() {
    if ($(this).val() === 'contains_text_and_length_is_less_than_x') {
      $('#message-length-box').show();
    } else {
      $('#message-length-box').hide();
    }
  });

  $('#destroy-rule').click(function(evt) {
    if (!$('#destroy-rule').attr('isDestroy')) {
      FlashHandler.setConfirmationDialog(
        '#destroy-rule',
        'Are you sure you want to delete rule?',
        'Delete Rule',
        'isDestroy'
      );
      return false;
    }
  });
});
