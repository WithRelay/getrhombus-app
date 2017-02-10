$(document).ready(function() {


  // bind emoji to textarea
  var reply_body_emoji_box = $('#saved-reply-body-field').emojioneArea({
    pickerPosition: 'bottom',
  });

  // Confirmation dialog box for destroy saved reply
  $('#delete-saved-reply').click(function(evt) {
    if (!$('#delete-saved-reply').attr('isDestroy')) {
      FlashHandler.setConfirmationDialog('#delete-saved-reply','Confirmation Needed', 'Are you sure?', 'isDestroy' )
      return false;
    }
  });
});
