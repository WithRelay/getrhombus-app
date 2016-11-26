// flash success for all types of flash messages
// the first parameter is message and second parameter is type eg: success
function setFlashMessage(msg, type){
  var typeObj = { 'notice': 'success', 'warning': 'info', 'error':'error' };
  var messageToSet = typeObj[type] || 'Attention';
  new PNotify({
    title: messageToSet + '!!',
    text: arrayToString(msg),
    type: messageToSet,
    hide: true
  });
}

function arrayToString(value){
  if ($.isArray(value)) {
    messageString = ''
    $.each(value, function(index, value){ messageString += value + "\n"; })
    return messageString;
  } else {
    return value;
  }
}

// Confirmation
function flashConfirm(selector, title, confirmText, isConfirm){
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
    stack: {'dir1': 'down', 'dir2': 'right', 'modal': true}
  })).get().on('pnotify.confirm', function() {
    $(selector).attr(isConfirm, true);
    $(selector)[0].click();
  }).on('pnotify.cancel', function() {
    return false;
  });
}
