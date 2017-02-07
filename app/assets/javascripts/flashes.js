// flash success for all types of flash messages
// the first parameter is message and second parameter is type eg: success
var FlashHandler = new function() {
  // toast message for error, success, notice
  this.setFlashMessage = function(msg, type){
    var typeObj = { 'notice': 'success', 'warning': 'info', 'error':'error' };
    var messageToSet = typeObj[type] || 'Attention';
    showToastr (messageToSet, arrayToString(msg));
    $('.toasters-close').on('click', function (e) {
      e.preventDefault();
      $('.toasters').fadeOut(5000);
    } );
  };

  function showToastr (type, message) {
    var class_name = (type === 'error') ? 'failure toasters' : 'toasters' ;
    $('body').append('<div class="'+class_name+'">\
      <div class="toaster-row w-row">\
        <div class="toaster-row-column-1 w-col w-col-11">\
          <div class="shrink-text toaster-text">\
            '+message+'\
          </div>\
        </div>\
        <div class="toaster-row-column-2 w-clearfix w-col w-col-1">\
          <div class="toaster-font-awesome toasters-close"></div>\
        </div>\
      </div>\
    </div>');
  }

  function incoming_facebook_message(profile_pic, customer_name, message) {
    $('body').append('<a class="browser-notification-link-block w-inline-block" href="#">\
      <div class="browser-notification-row w-row">\
        <div class="browser-notification-row-column-1 w-clearfix w-col w-col-4">\
          <img class="browser-notification customer-profile-picture" height="40" src="'+profile_pic+'" width="40">\
        </div>\
        <div class="browser-notification-row-column-2 w-clearfix w-col w-col-8">\
          <div class="browser-notification customer-name-text shrink-text">\
            <strong class="customer-name-browser-notification">'+customer_name+'</strong>\
          </div>\
          <div class="break-word browser-notification-preview word-wrap">'+message+'</div>\
          <div class="browser-notification-close toaster-font-awesome"></div>\
        </div>\
      </div>\
    </a>')
    close_browser_toastr();    
  }


  function incoming_sms (profile_pic, customer_name, message) {
    $('body').append('<a class="browser-notification-link-block sms-browser-notification w-inline-block" href="#">\
      <div class="browser-notification-row w-row">\
        <div class="browser-notification-row-column-1 payment-notification w-clearfix w-col w-col-4">\
          <img class="browser-notification customer-profile-picture" height="40" src="'+profile_pic+'" width="40">\
        </div>\
        <div class="browser-notification-row-column-2 w-clearfix w-col w-col-8">\
          <div class="browser-notification customer-name-text shrink-text">\
            <strong class="customer-name-browser-notification">'+customer_name+'</strong>\
          </div>\
          <div class="break-word browser-notification-preview word-wrap">'+message+'</div>\
          <div class="browser-notification-close sms toaster-font-awesome"></div>\
        </div>\
      </div>\
    </a>')
    close_browser_toastr();
  }

  function payment_notification(profile_pic, amount, customer_name) {
    $('body').append('<a class="browser-notification-link-block payment w-clearfix w-inline-block" href="#">\
      <img class="browser-notification customer-profile-picture" height="40" src="'+profile_pic+'" width="40">\
      <div class="payment-notification-amount">$'+amount+'</div>\
      <div class="browser-notification-close payment toaster-font-awesome"></div>\
      <div class="payment-sender-name shrink-text">'+customer_name+'.</div>\
    </a>')
    close_browser_toastr();
  }

  function copied_no() {
    $('body').append('<a class="browser-notification-link-block copied w-inline-block" href="#">\
      <div class="browser-notification-close payment toaster-font-awesome"></div>\
      <div class="number-copied-text">Phone number copied!</div>\
    </a>')
    close_browser_toastr();
  }

  function schedule_jobs (message, no_of_recipient) {
    $('body').append('<a class="browser-notification-link-block scheduled-jobs w-inline-block" href="#">\
      <div class="scheduled-jobs-notification-description">'+message+'</div>\
      <img class="browser-notification customer-profile-picture scheduled-jobs" height="40" src="http://uploads.webflow.com/58977e002a25945021983468/58977e002a2594502198356c_81.jpg" width="40">\
      <img class="browser-notification customer-profile-picture next-receipient scheduled-jobs" height="40" src="http://uploads.webflow.com/58977e002a25945021983468/58977e002a25945021983515_Ovo.jpg" width="40">\
      <img class="browser-notification customer-profile-picture next-receipient scheduled-jobs" height="40" src="http://uploads.webflow.com/58977e002a25945021983468/58977e002a25945021983540_31.jpg" width="40">\
      <img class="browser-notification customer-profile-picture next-receipient scheduled-jobs" height="40" src="http://uploads.webflow.com/58977e002a25945021983468/58977e002a2594502198351f_49%20(1).jpg" width="40">\
      <img class="browser-notification customer-profile-picture next-receipient scheduled-jobs" height="40" src="http://uploads.webflow.com/58977e002a25945021983468/58977e002a2594502198357c_49%20(2).jpg" width="40">\
      <div class="recipient-count-browser">\
        <div class="number-of-recipient shrink-text">+'+no_of_recipient+'</div>\
      </div>\
    </a>')
    $('.scheduled-jobs').fadeOut(10000);
  }

  function close_browser_toastr() {
    $('.browser-notification-close').on('click', function (e) {
      e.preventDefault();
      $('.browser-notification-link-block').fadeOut(5000);
    } );
  }

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

