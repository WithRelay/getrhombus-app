$(document).ready(function() {


  // bind emoji to textarea
  var reply_body_emoji_box = $('#Saved-Replies-Editor-3').emojioneArea({
    pickerPosition: 'bottom',
  });

  var reply_body_emoji_box = $('#Edit-Saved-Replies-Editor').emojioneArea({
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
