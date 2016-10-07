$( document ).ready(function() {
  "use strict";
  setTimeout(function() {
      toastr.options = {
          closeButton: true,
          progressBar: true,
          showMethod: 'slideDown',
          timeOut: 4000
      };
      toastr.success('A Message Commerse Platform', 'Welcome to GETRHOMBUS');

  }, 1300);

  var index = 1;
  if ($('#select_page').length > 0){
    check_status($('#select_page').val().split(' ')[index]);
    $( '#select_page' ).change(function() {
      check_status($(this).val().split(' ')[index]);
    });
  }

  $(document).on('click', '.submit_page', function() {
    var name = $(this).attr('param');
    if ($(this).val() === "Subscribe"){
      toastr.success( name + ', page has been successfully subscribed.');
    } else {
      toastr.warning( name + ', your page has been unsubscribed.');
    }
  });

  $('#delete_integration').click(function (evt) {
    evt.preventDefault();
    swal({
      title: "Are you sure?",
      text: "Your will not be able to see conversation on page!",
      type: "warning",
      showCancelButton: true,
      confirmButtonColor: "#dd1c06",
      confirmButtonText: "Yes, delete it!",
      cancelButtonText: "No, cancel it!",
      closeOnConfirm: false,
      closeOnCancel: false },
      function (isConfirm) {
      if (isConfirm) {
        swal("Removed!", "Your facebook integration has been removed.", "success");
        window.location = $('#delete_integration').attr('href');
      } else {
        swal("Cancelled", "Your Facebook messages are safe :)", "error");
        return false;
      }
    });
  });
});

function check_status(val){
  if (val === 'false'){
    $('.submit_page').val('Subscribe');
  }
  else{
    $('.submit_page').val('Unsubscribe');
  }
}
