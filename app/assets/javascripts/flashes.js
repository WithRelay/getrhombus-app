// flash success for all types of flash messages
// the first parameter is message and second parameter is type eg: success
var FlashHandler = new function() {
  // toast message for error, success, notice
  this.setFlashMessage = function(msg, type){
    var typeObj = { 'notice': 'success', 'warning': 'info', 'error':'error' };
    var messageToSet = typeObj[type] || 'Attention';
    new PNotify({
      title: messageToSet + '!!',
      text: arrayToString(msg),
      type: messageToSet,
      hide: true
    });
  };

  // Confirmation Dialog for event
  var stack = {'dir1': 'down', 'dir2': 'right', 'modal': true};
  this.setConfirmationDialog = function (selector, title, confirmText, isConfirm){
    (new PNotify({
      title: title,
      text: confirmText,
      icon: 'glyphicon glyphicon-question-sign',
      hide: false,
      confirm: {
        confirm: true
      },
      buttons: {
        closer: false,
        sticker: false
      },
      history: {
        history: false
      },
      addclass: 'stack-modal',
      stack: stack
    })).get().on('pnotify.confirm', function() {
      $(selector).attr(isConfirm, true);
      $(selector)[0].click();
    }).on('pnotify.cancel', function() {
      return false;
    });
  };

  // when multiple flash message are present it converts it to multiline flash message
  function arrayToString(value){
    if ($.isArray(value)) {
      messageString = ''
      $.each(value, function(index, value){ messageString += value + "\n"; })
      return messageString;
    } else {
      return value;
    }
  }

}
