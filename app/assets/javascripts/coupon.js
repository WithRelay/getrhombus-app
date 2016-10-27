$(document).ready(function () {
  var date = new Date();
  var today = new Date(date.getFullYear(), date.getMonth(), date.getDate());
  $('input[name="coupon[redeem_by]"]').daterangepicker({
    defaultViewDate: today,
    timePickerIncrement: 30,
    showDropdowns: true,
    singleDatePicker: true,
    minDate: today,
    format: 'mm/dd/yyyy',
    pickDate: true,
    todayHighlight: true,
    weekStart: 0,
    opens: "center"
 });

})