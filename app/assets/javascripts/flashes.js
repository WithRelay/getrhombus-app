
// flash success for warning
function setFlashMessage(msg, type){
  var typeObj = { 'Notice': 'Success', 'Warning': 'info', 'Error':'error' }
  var messageToSet = typeObj[type]
  new PNotify({
    title: messageToSet,
    text: arrayToString(msg),
    type: messageToSet,
    hide: true
  });
}
function arrayToString(value){
  if ($.isArray(value)){
    messageString = ''
    $.each(value, function(index, value){ messageString += value + "\n"; })
    return messageString
  }
    else {
      return value
    }
}
function flashAlert(alertMsg){
  var notice = new PNotify({
     title: 'Alert!!',
     text: arrayToString(infoMsg),
     buttons: {
         closer: false,
         sticker: false
     }
   });
   notice.get().click(function() {
       notice.remove();
   });
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
    $(selector).click();
  }).on('pnotify.cancel', function() {
    return false;
  });
}
