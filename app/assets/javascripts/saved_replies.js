$(document).ready(function() {

  // all checked

  // bind emoji to textarea
  var new_reply_emoji_box = $('#Saved-Replies-Editor-3').emojioneArea({
    pickerPosition: 'bottom',
  });

  var reply_emoji_box = $('#Edit-Saved-Replies-Editor').emojioneArea({
    pickerPosition: 'bottom',
  });

  function create_saved_reply(formData){
    $.ajax({
      url: window.location.origin + "/v1/saved_replies",
      method: "POST",
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

  $('.save-reply-form').submit(function(){
    $(this).formValidation('revalidateField', 'saved_reply[body]');
  });

  formValidation('.save-reply-form');

  function formValidation(form){
    if ($(form).length) {
      $(form).formValidation({
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
                message: 'This field is required'
              }
            }
          },
          'saved_reply[title]': {
            validators: {
              notEmpty: {
                message: 'This field is required'
              }
            }
          },
        }
      }).on('success.form.fv', function(e, data) {
        if (this.id != 'edit-save-reply-form'){
          e.preventDefault();
          create_saved_reply($(this).serialize());
        };
      });
    }
  };

  $('#edit-saved-reply').on('click',function(e) {
    var selectedElement = CheckedItem.get();
    
    if (selectedElement == false) {
      FlashHandler.setFlashMessage('Please select a reply', 'error');
      return false;
    }
   
    $("#edit-saved-reply-modal").lightbox_me({
      centered: true,
      overlayCSS: {
        background: 'rgba(99,114,130,0.5)', opacity: .8
      }
    });

    var form = $('#edit-save-reply-form');
    var reply_id = selectedElement.closest('form').find('#saved_reply_id').val();
    var newAction = window.location.origin + '/users/' + UserDetails.id() + '/saved_replies/' + reply_id;

    form.find("#Edit-Saved-Reply-Title").val(selectedElement.data('title'));
    reply_emoji_box[0].emojioneArea.setText(selectedElement.data('body'));
    form.attr('action', newAction);
  });

  // reviewed
  // Confirmation dialog box for destroy saved reply
  $('#delete-saved-reply').click(function(evt) {
    var selectedElement = CheckedItem.get();
    if (!selectedElement) {
      FlashHandler.setFlashMessage('Please select a reply', 'error');
    } else {
      var id = '#saved_reply-delete-' + selectedElement.data('obj-id');
      FlashHandler.setConfirmationDialog(id, 'Are you sure you want to delete the reply?', 'Delete');
    };
    return false;
  });

});
