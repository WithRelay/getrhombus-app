// flash success for ajax response
function flashSuccess(successMsg){
  new PNotify({
    title: 'Success!!',
    text: arrayToString(successMsg),
    type: 'success',
    hide: true
  });
}

// flash success for warning
function flashWarning(warningMsg){
  new PNotify({
    title: 'Info!!',
    text: arrayToString(warningMsg),
    type: 'info',
    hide: true
  });
}
// flash success for ajax response
function flashError(errorMsg){
  new PNotify({
    title: 'Error!!',
    text: arrayToString(errorMsg),
    type: 'error',
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
// flash info with desktop notification permission
function flashNotice(infoMsg){
  new PNotify({
    title: 'Info!!',
    text: arrayToString(infoMsg),
    type: 'info',
    hide: true
  });
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
