$(document).ready(function() {

  var action,
    id = $('.saved-reply-title'), // hold title for now..will change to the actual id
    form = $('#saved-reply-form');


  // set first id
  if (id.length > 0) id = id[0].id.split('-')[3];


  // when a saved reply is click populate form fields and rebuild links
  $('.saved-reply-title').click(function() {
    id = this.id.split('-')[3];
    action = form.attr('action');
    action = action.substring(0, action.lastIndexOf('/') + 1) + id;

    form.attr('action', action);
    $('#delete-saved-reply').attr('href', action)

    set_title_and_body();
  });


  // return saved reply to original state
  $('#saved-reply-cancel').click(function(e) {
    e.preventDefault();
    set_title_and_body();
  });


  // bind emoji to textarea
  var reply_body_emoji_box = $('#saved-reply-body-field').emojioneArea({
    pickerPosition: 'bottom',
  });


  function set_title_and_body() {
    $('#saved-reply-title-field').val($('#saved-reply-title-' + id).text());
    reply_body_emoji_box[0].emojioneArea.setText($('#saved-reply-body-' + id).text());
  }

  // Confirmation dialog box for destroy saved reply
  $('#delete-saved-reply').click(function(evt) {
    if (!$('#delete-saved-reply').attr('isDestroy')) {
      flashConfirm('#delete-saved-reply','Confirmation Needed', 'Are you sure?', 'isDestroy' )
      return false;
    }
  });
});
