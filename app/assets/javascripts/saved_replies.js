$(document).ready(function() {


  // bind emoji to textarea
  var reply_body_emoji_box = $('#Saved-Replies-Editor-3').emojioneArea({
    pickerPosition: 'bottom',
  });

  var reply_body_emoji_box = $('#Edit-Saved-Replies-Editor').emojioneArea({
    pickerPosition: 'bottom',
  });

  function create_saved_reply(formData){
    $.ajax({
      url: window.location.origin + "/v1/saved_replies",
      method: "POST",
      data: formData,
      dataType: 'json'
    }).done(function(res){
      FlashHandler.setFlashMessage(res.notice,'notice');
      location.reload();
      }).error(function(res){
        FlashHandler.setFlashMessage(res.error, 'error');
    });
  }

  //if ($('.save-reply-form').length) {
    $('#save-reply-form').formValidation({
      framework: 'bootstrap',
      excluded: ':disabled',
      live: 'disabled',
      err: {
            container: function($field, validator) {
                return $field.parent().find('.messageContainer');
            }
        },
      fields: {
        'saved_reply[body]': {
          validators: {
            notEmpty: {
              message: 'This Field is required'
            }
          }
        },

        'saved_reply[title]': {
          validators: {
            notEmpty: {
              message: 'This Field is required'
            }
          }
        },

        }
    }).on('success.form.fv', function(e, data) {
      if (this.id != 'edit-save-reply-form'){
        e.preventDefault();
        create_saved_reply($(this).serialize());
      }

      $('.update-close-modals').click();
    });
  // }


});
