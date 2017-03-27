$(document).ready(function(){
  enableEmojiCounter("#Away-Message-Auto-Response")

  $('#enable-away-message').click(function(){
    if($(this).is(":checked"))
      $('#away-message-text-area').slideDown();
  });

  function enableEmojiCounter(element){
    $(element).emojioneArea();
    $(element).counter({ type: 'char', append: false, goal: 150, target: '#away-message-counter' })
  }
})
