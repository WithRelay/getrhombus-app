// flash success for ajax response
function flashSuccess(successMsg){
  new PNotify({
    title: 'Success!!',
    text: successMsg,
    type: 'success',
    hide: true
  });
}

// flash success for warning
function flashWarning(warningMsg){
  new PNotify({
    title: 'Info!!',
    text: warningMsg,
    type: 'info',
    hide: true
  });
}
// flash success for ajax response
function flashError(errorMsg){
  new PNotify({
    title: 'Error!!',
    text: errorMsg,
    type: 'error',
    hide: true
  });
}

// flash info with desktop notification permission
function flashInfo(infoMsg){
  PNotify.desktop.permission();
  (new PNotify({
    title: 'Info!!',
    text: infoMsg,
    type: 'info',
    hide: true,
    desktop: {
      desktop: true
    }
  })).get().click(function(e) {
    if ($('.ui-pnotify-closer, .ui-pnotify-sticker, .ui-pnotify-closer *, .ui-pnotify-sticker *').is(e.target)) return;
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
