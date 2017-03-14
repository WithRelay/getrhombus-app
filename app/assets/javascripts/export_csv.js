$(document).ready(function () {
  $('#Date-Range-Picker').daterangepicker({
    cancelClass: 'hide',
    linkedCalendars: true,
    /*timePicker: true,
    timePickerIncrement: 30,
    singleDatePicker: true,
    locale: {
        format: 'MM/DD/YYYY h:mm A'
    },*/
   ranges: {
       'Today': [moment(), moment()],
       'Yesterday': [moment().subtract(1, 'days'), moment().subtract(1, 'days')],
       'Last 7 Days': [moment().subtract(6, 'days'), moment()],
       'Last 30 Days': [moment().subtract(29, 'days'), moment()],
       'This Month': [moment().startOf('month'), moment().endOf('month')],
       'Last Month': [moment().subtract(1, 'month').startOf('month'), moment().subtract(1, 'month').endOf('month')]
    },
    alwaysShowCalendars: true,
    //maxDate: new Date
  })
  .on('apply.daterangepicker', function(ev, picker) {
    $('#txn_start_date').val(picker.startDate.format('YYYY-MM-DD'));
    $('#txn_end_date').val(picker.endDate.format('YYYY-MM-DD'));
    $('#txn_history_form').submit();
  });

  $('#Date-Range-Picker-2').daterangepicker({
    cancelClass: 'hide',
    linkedCalendars: true,
    /*timePicker: true,
    timePickerIncrement: 30,
    singleDatePicker: true,
    locale: {
        format: 'MM/DD/YYYY h:mm A'
    },*/
   ranges: {
       'Today': [moment(), moment()],
       'Yesterday': [moment().subtract(1, 'days'), moment().subtract(1, 'days')],
       'Last 7 Days': [moment().subtract(6, 'days'), moment()],
       'Last 30 Days': [moment().subtract(29, 'days'), moment()],
       'This Month': [moment().startOf('month'), moment().endOf('month')],
       'Last Month': [moment().subtract(1, 'month').startOf('month'), moment().subtract(1, 'month').endOf('month')]
    },
    alwaysShowCalendars: true,
    //maxDate: new Date
  })
  .on('apply.daterangepicker', function(ev, picker) {
    $('#subs_txn_start_date').val(picker.startDate.format('YYYY-MM-DD'));
    $('#subs_txn_end_date').val(picker.endDate.format('YYYY-MM-DD'));
    $('#subs_txn_history_form').submit();
  });
});
