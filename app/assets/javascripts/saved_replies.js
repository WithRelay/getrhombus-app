$(document).ready(function() {

  var action,
    id = $('.saved-reply-title'), // hold title for now..will change to the actual id
    form = $('#saved-reply-form');

    $('#saved-reply-body-field').emojioneArea();

  // set first id
  if (id.length > 0) id = id[0].id.split('-')[3];


  // when a saved reply is click populate form fields and rebuild links
  $('.saved-reply-title').click(function() {

    id = this.id.split('-')[3];

    action = form.attr('action');
    
    // $('#delete-saved-reply').attr('href', action)
    saved_reply = {}
    saved_reply['saved_reply'] =  { 'id': id }
    sendRequest(saved_reply, action, ['#saved-reply-title-field', '.emojionearea-editor', 
      '.hidden-id-field'])

    set_title_and_body();
  });

  $('#email-form-8').submit(function(e){
    e.preventDefault();
  });

  $('#send-saved-reply').click(function(){
     action = $('#email-form-8').attr('action');
     sendRequest($('#email-form-8').serialize(), action);
  });

  $('#save-reply-button').click(function(e){
    e.preventDefault();
    url = $('#saved-reply-edit-new').attr('action')
    sendRequest($('#saved-reply-edit-new').serialize(), url);
  });

  function sendRequest(data, action, div_elements = []){
    $.ajax({
      url: action,
      type: "post",
      data: data,
      dataType: "json"
    })
    .done(function(msg){
      if (div_elements.length > 0 ){
        $(div_elements[0]).val(msg.save_reply.title);
        $(div_elements[1]).text(msg.save_reply.body);
        $(div_elements[2]).val(msg.save_reply.id);
      }
      else{
        var flash_key = Object.keys(msg)[0]
        // set flash message title and message
        // first argument is title and second is text message.
        FlashHandler.setFlashMessage( msg[flash_key], flash_key )
      }
    }).fail(function(msg){ alert('Sorry request could not complete'); });
  }

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
      FlashHandler.setConfirmationDialog('#delete-saved-reply','Confirmation Needed', 'Are you sure?', 'isDestroy' )
      return false;
    }
  });
});
