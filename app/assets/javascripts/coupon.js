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

  // validate coupon form
    $('#couponForm')
      .formValidation({
        framework: 'bootstrap',
        icon: {
                        valid: 'glyphicon glyphicon-ok',
                        invalid: 'glyphicon glyphicon-remove',
                        validating: 'glyphicon glyphicon-refresh'
                    },
        // List of fields and their validation rules
        fields: {
            'coupon[name]': {
                row: '.field',
                validators: {
                    notEmpty: {
                        message: 'Coupon name is required'
                    }
                }
            },
            'coupon[amount_off]': {
                selector: '#coupon-type-value',
                row: '.field',
                validators: {
                    notEmpty: {
                        message: 'Amount or Percent off  is required'
                    }
                }
            }
          }
        })
      .on('err.validator.fv', function(e, data) {
          // $(e.target)  --> The field element
          // data.fv      --> The FormValidation instance
          // data.field   --> The field name
          // data.element --> The field element

          // Hide the messages
          data.element
              .data('fv.messages')
              .find('.help-block[data-fv-for="' + data.field + '"]').show();
      })
      .on('success.validator.fv', function(e, data) {
          data.element // Get the field element
          .closest('.field') // Get the field parent

          // Add has-warning class
          .removeClass('has-success')
          .addClass('has-warning')
      });
})
