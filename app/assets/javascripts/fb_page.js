  $( document ).ready(function() {
  "use strict";
  var index = 1;
  if ($('#select_page').length > 0){
    check_status($('#select_page').val().split(' ')[index]);
    $( '#select_page' ).change(function() {
      check_status($(this).val().split(' ')[index]);
    });
  }

  $('.submit_page').click(function (evt) {
    if (($(this).val() === 'Subscribe') && ($(this).attr('subscribed_page'))) {
      if (!$(".submit_page").attr('canSubscribe')) {
        evt.stopImmediatePropagation();
        (new PNotify({
          title: 'Change Facebook Page',
          text: 'Existing conversations linked to your previous Facebook page will stop being synced to your business app integrations. Continue?',
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
            $('.submit_page').attr('canSubscribe', true);
            $('.submit_page').click();
          }).on('pnotify.cancel', function() {
            return false;
        });
        return false;
      }
    }
    else if(($(this).val() === 'Unsubscribe')){
      if (!$(".submit_page").attr('canUnsubscribe')) {
        evt.stopImmediatePropagation();
        (new PNotify({
          title: 'Are you sure?',
          text: 'Existing conversations linked to this Facebook page will stop being synced to your business app integrations. Continue?',
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
            $('.submit_page').attr('canUnsubscribe', true);
            $('.submit_page').click();
          }).on('pnotify.cancel', function() {
            return false;
        });
        return false;
      }
    }
  });

  $('#delete_integration').click(function (evt) {
    evt.preventDefault();
    swal({
      title: "Rhombus Facebook Messenger Integration",
      text: "Are you sure, you want to remove the integration?",
      type: "warning",
      showCancelButton: true,
      confirmButtonColor: "#dd1c06",
      confirmButtonText: "Remove",
      cancelButtonText: "Cancel",
      closeOnConfirm: false,
      closeOnCancel: false },
      function (isConfirm) {
      if (isConfirm) {
        swal("Removed!", "You have disconnected Facebook Messenger from Rhombus.", "success");
        window.location = $('#delete_integration').attr('href');
      } else {
        swal("Cancelled", "You are still connected with Rhombus", "error");
        return false;
      }
    });
  });
});

function check_status(val){
  if (!val) {
    $('.submit_page').hide();
  }
  else if (val === 'false'){
    $('.submit_page').show();
    $('.submit_page').val('Subscribe');
    $('.submit_page').attr('class', 'submit_page btn btn-success');
  }
  else{
    $('.submit_page').show();
    $('.submit_page').val('Unsubscribe');
    $('.submit_page').attr('class', 'submit_page btn btn-warning');
  }
}
