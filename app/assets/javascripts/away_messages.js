$(document).on('ready page:load', function() {

  var autoResponseTextBox = '#Away-Message-Auto-Response'

  $('#enable-away-message').is(":checked") && $('#away-message-text-area').slideDown();

  if ($(autoResponseTextBox).length > 0){
    enableEmojiCounter(autoResponseTextBox)
    $(autoResponseTextBox)[0].emojioneArea.on('focus', function(){
      $('#undefined_counter').each(function(){ $(this).remove() });
      $('.emojionearea-editor').counter({ type: 'char', append: false, target: '#away-message-counter' })
    });
  }
  $('#enable-away-message').click(function(){
    if($(this).is(":checked")){
      $('#away-message-text-area').slideDown();
    }else{
      $('#away-message-text-area').hide();
    }
  });

  $('#save-away-message-button').click(function(e){
    if ($('#enable-away-message').is(':checked') && $(autoResponseTextBox).val() == ''){
      $('.emojionearea').attr('style', 'border: 1px solid red;')
      e.preventDefault();
    }
    else{
      $('.emojionearea').removeAttr('style')
    }
  });

  function enableEmojiCounter(element){
    $(element).emojioneArea();
  }
})
