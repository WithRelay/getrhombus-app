// flash success for all types of flash messages
// the first parameter is message and second parameter is type eg: success
var FlashHandler = new function() {
  var focused = true;

  window.onfocus = window.onblur = function(e) {
    focused = (e || event).type === "focus";
  }

// ask for the enable browser notification permission
  this.notificationPermission = function () {
    if(Notification.permission !== 'granted'){
      Notification.requestPermission();
    }
  }

  function browserNotification(title, message){
    var chck = Notification.permission;
    if( chck === 'granted' ){
      var notification = new Notification( title, {
        body: message
      });
      notification.onclick = function () {
        notification.close();
        window.focus();
      };
    }
  }

  // toast message for error, success, notice, alert
  var typeObj = { 'notice': 'success', 'warning': 'info', 'error':'error', 'errors': 'error', 'alert': 'error' };
  this.setFlashMessage = function(msg, type){
    var messageToSet = typeObj[type] || 'Attention';
    showToastr(messageToSet, arrayToString(msg));
    if (typeObj[type] !== 'error') { $('.toasters').fadeOut(7000);}
    $('.toaster-font-awesome').on('click', function (e) {
      e.preventDefault();
      $('.toasters').fadeOut(3000);
    } );
  };

  function showToastr(type, message) {
    hideToastr();

    var class_name = (type === 'error') ? 'failure toasters' : 'toasters' ,
        close_button_class = (type === 'error') ? 'failure toaster-font-awesome' : 'toaster-font-awesome'
    $('body').prepend('<div class="'+class_name+'">\
      <div class="toaster-row w-row">\
        <div class="toaster-row-column-1 w-col w-col-11">\
          <div class="shrink-text toaster-text">\
            '+message+'\
          </div>\
        </div>\
        <div class="toaster-row-column-2 w-clearfix w-col w-col-1">\
          <div class="'+close_button_class+'"></div>\
        </div>\
      </div>\
    </div>');
  }

  function hideToastr(){
    $('.browser-notification-link-block, .toasters').remove();
  }

  this.incoming_facebook_message = function(profile_pic, customer_name, message) {
    hideToastr();
    if (focused === false) {
      browserNotification('New Message', message);
    }
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
  };

  this.incoming_sms = function(profile_pic, customer_name, message) {
    hideToastr();
    if (focused === false) {
      browserNotification('New Message', message);
    }
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
  };

  this.payment_notification = function(profile_pic, amount, customer_name) {
    hideToastr();
    if (focused === false) {
      browserNotification('New payment', amount);
    }
    $('body').append('<a class="browser-notification-link-block payment w-clearfix w-inline-block" href="#">\
      <img class="browser-notification customer-profile-picture" height="40" src="'+profile_pic+'" width="40">\
      <div class="payment-notification-amount">$'+amount+'</div>\
      <div class="browser-notification-close payment toaster-font-awesome"></div>\
      <div class="payment-sender-name shrink-text">'+customer_name+'.</div>\
    </a>')
    close_browser_toastr();
  };

  this.copied_no = function() {
    hideToastr();
    $('body').append('<a class="browser-notification-link-block copied w-inline-block" href="#" style="position: absolute;">\
      <div class="browser-notification-close payment toaster-font-awesome"></div>\
      <div class="number-copied-text">Phone number copied!</div>\
    </a>');
    close_browser_toastr();
  }

  this.schedule_jobs = function(message, no_of_recipient) {
    hideToastr();
    if (focused === false) {
      browserNotification('New Campaign sent', message);
    }
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
  this.setConfirmationDialog = function (selector, confirmText, confirmDialog, isConfirm){
    hideToastr();

    $('body').append('<div class="cancel-subscription-wrapper w-clearfix">\
      <p class="cancel-subscription modal-content-description">'+confirmText+'</p>\
      <div class="modal-underline underline-div"></div>\
      <a class="button cancel-yes w-button" href="#">'+confirmDialog+'</a>\
      <a class="button cancel-no w-button" href="#">Cancel</a>\
    </div>');

    $('.cancel-subscription-wrapper').lightbox_me({
      centered: true
    });

    $('.cancel-no').on('click', function(e){
      $('.cancel-subscription-wrapper').remove();
      $('.js_lb_overlay').remove();
      return false;
    })

    $('.cancel-yes').on('click', function(){
      $(selector).attr(isConfirm, true);
      $('.cancel-yes')[0].innerHTML = 'Please wait...';
      $(selector)[0].click();
    })
  };

  // when multiple flash message are present it converts it to multiline flash message
  function arrayToString(value){
    if ($.isArray(value)) {
      messageString = ''
      $.each(value, function(index, value){ messageString += value + "<br>"; })
      return messageString;
    } else {
      return value;
    }
  }

}
