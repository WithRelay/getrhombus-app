$(document).ready(function () {
  RAILS_DATE_FORMAT = 'DD/MM/YYYY h:mm A'
  var date = new Date();
  var tomorrow = new Date(date.getFullYear(), date.getMonth(), date.getDate()+1);
  $('input[name="coupon[redeem_by]"]').daterangepicker({
    autoUpdateInput: false,
    timePickerIncrement: 1,
    showDropdowns: true,
    singleDatePicker: true,
    minDate: tomorrow,
    todayHighlight: true,
    timePicker: true,
    timePickerIncrement: 1,
    locale: {
      format: RAILS_DATE_FORMAT,
      cancelLabel: 'Clear'
   },
    weekStart: 0,
    opens: "left",
    drops: 'up'
  });

  $('input[name="coupon[redeem_by]"]').on('apply.daterangepicker', function(ev, picker) {
    $(this).val(picker.startDate.format(RAILS_DATE_FORMAT));
  });

  $('input[name="coupon[redeem_by]"]').on('cancel.daterangepicker', function(ev, picker) {
    $(this).val('');
  });

  $('.delete-coupon').click(function(evt) {
    if (!$('.delete-coupon').attr('isDestroy')) {
      flashConfirm('.delete-coupon','Confirmation Needed', 'Are you sure?', 'isDestroy' );
      return false;
    }
  });
})