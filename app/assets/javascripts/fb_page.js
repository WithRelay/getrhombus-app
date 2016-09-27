$( document ).ready(function() {
  var index = 1, select_page = '#select_page';
  if ($(select_page).length > 0) {
    check_status($(select_page).val().split(' ')[index]);
  }
  $(select_page).change(function() {
    check_status($(this).val().split(' ')[index]);
  });
});

function check_status(val){
  if (val === "false"){
    $(".submit_page").val('Subscribe');
  }
  else{
    $(".submit_page").val('Unsubscribe');
  }
}
