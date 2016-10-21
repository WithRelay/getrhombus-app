  $( document ).ready(function() {
  "use strict";
  var index = 1;
  if ($('#select_page').length > 0){
    check_status($('#select_page').val().split(' ')[index]);
    $( '#select_page' ).change(function() {
      check_status($(this).val().split(' ')[index]);
    });
  }

  $('#delete_integration').click(function (evt) {
    evt.preventDefault();
    swal({
      title: "Rhombus Facebook Messenger Integration",
      text: "Are you sure you want to remove the Facebook Messenger integration from this app?",
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
