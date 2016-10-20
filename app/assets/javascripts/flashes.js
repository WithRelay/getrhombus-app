// flash success for ajax response
function flashSuccess(successMsg){
  PNotify.desktop.permission();
  (new PNotify({
    title: 'Success!!',
    text: successMsg,
    type: 'success',
    hide: true,
    desktop: {
      desktop: true
    }
  })).get().click(function(e) {
    if ($('.ui-pnotify-closer, .ui-pnotify-sticker, .ui-pnotify-closer *, .ui-pnotify-sticker *').is(e.target)) return;
  });
}

// flash success for ajax response
function flashError(errorMsg){
  PNotify.desktop.permission();
  (new PNotify({
    title: 'Error!!',
    text: errorMsg,
    type: 'error',
    hide: true,
    desktop: {
      desktop: true
    }
  })).get().click(function(e) {
    if ($('.ui-pnotify-closer, .ui-pnotify-sticker, .ui-pnotify-closer *, .ui-pnotify-sticker *').is(e.target)) return;
  });
}

// flash info
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
