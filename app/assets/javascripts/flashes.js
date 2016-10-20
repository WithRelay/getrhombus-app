// flash success for ajax response
function flashSuccess(successMsg){
  new PNotify({
    title: 'Success!!',
    text: successMsg,
    type: 'success',
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

// flash info
function flashInfo(infoMsg){
  new PNotify({
    title: 'Info!!',
    text: infoMsg,
    type: 'info',
    hide: true
  });
}
