$(document).ready(function () {

  // all reviewed

  //  Hashtags, plans, coupons, Alerts
  var coupon_type_value  = $('#coupon-type-value');
  var coupon_type = $('#coupon-type');
  var msg_emoji_box, emoji_area_text_length;

  // emojionearea
  if ($("#hashtag-response-textarea").length) {
    var msg_emoji_box =  $('#hashtag-response-textarea').emojioneArea({
      pickerPosition: "bottom"
    });

    $(window).load(function(){
      $('.emojionearea-editor').counter({
        count: "down",
        goal: 300,
        target: '#char-count',
        msg: 'character(s)'
      });
    });

    msg_emoji_box[0].emojioneArea.on('change', function(e) {
      $('#new_hashtag').formValidation('resetField', 'hashtag[response]');
    });
  };

  // no spaces
  $('#hashtag_tag, #coupon-name').on('input', function(){ this.value = this.value.replace(/\s+/g, ''); });

  // Positive integer only
  $('#duration-in-months, #max-redemptions, #subscription_quantity').on('input', function(){
    this.value = positive_integer_only(this.value);
  });

  function positive_integer_only(v) {
    if (!(/^(\d+)$/.test(v))) return '';
    else {
      if (v.match(/^[1-9]\d*$/)) return v;
      else return v.slice(0, -1);
    }
  };

  function positive_integer_less_than_100(v) {
    if (!(/^(\d+)$/.test(v))) return '';
    else {
      if (v.match(/^[1-9]\d*$/) && parseInt(v) < 101) return v;
      else return v.slice(0, -1);
    }
  };

  function decimal_with_up_to_two_places(v) {
    if (!(/^(\d+)(\.)?(\d+)?$/.test(v))) return '';
    else {
      if (v.slice(-1) == '.' && (v.match(/[.]/g) || []).length == 1 && v.length > 1) return v;
      // http://stackoverflow.com/questions/30606348/check-if-a-given-value-is-a-positive-number-or-float-with-maximum-two-decimal-pl
      // http://stackoverflow.com/questions/25053605/regex-to-allow-only-a-single-dot-in-a-textbox
      else if (v.match(/^\d+(.\d{1,2})?$/)) return v;
      else return parseFloat(v).toFixed(2);
    }
  };

  // delete hashtag button
  $('#delete-hashtag').click(function(e) {
    var selectedElement = CheckedItem.get();
    if (selectedElement == false) {
      FlashHandler.setFlashMessage('Select a hashtag to delete', 'error');
    } else {
      var id = '#hashtag-delete-' + selectedElement.data('obj-id');
      FlashHandler.setConfirmationDialog(id, 'Are you sure you want to delete this hashtag?', 'Delete');
    };
    return false;
  });

  // deactivate hashtag button 
  $('#deactivate-hashtag').click(function() {
    var selectedElement = CheckedItem.get();
    if (selectedElement == false) {
      FlashHandler.setFlashMessage('Select a hashtag to change status', 'error');
    } else {
      FlashHandler.setConfirmationDialog('#deactivate-hashtag', 'Are you sure you want to change hashtag status?', 'Change');
    };
    return false;
  });

  // decimal with two places
  $('#hashtag_amount, #amount_1 ,#Plan-Amount, #charge-amount, #Add-Funds').on('input', function(e) {
    $(this).val(function(_, v) {
      return decimal_with_up_to_two_places(v);
    });
  });

  coupon_type_value.on('input', function(){
    var v = this.value;
    this.value = (coupon_type.val() == 'amount_off') ? decimal_with_up_to_two_places(v) : positive_integer_less_than_100(v);
  });

  coupon_type.on('change', function() {
    var name_value, placeholder_value;

    if (this.value == 'amount_off') {
      name_value = "coupon[amount_off]";
      placeholder_value = "Amount";
      $('#couponForm').formValidation('resetField', 'coupon[percent_off]');
    } else {
      name_value = "coupon[percent_off]";
      placeholder_value = "Percentage";
      $('#couponForm').formValidation('resetField', 'coupon[amount_off]');
    }

    coupon_type_value.val('').attr('name', name_value);
    coupon_type_value.attr('placeholder', placeholder_value);
  });

  // validate hashtag form
  $('#new_hashtag')
  .formValidation({
    framework: 'bootstrap',
    excluded: ':disabled',
    live: 'disabled',
    fields: {
      'hashtag[name]': {
        verbose: false,
        threshold: 2,
        validators: {
          notEmpty: {
            message: 'Name  is required'
           },
          remote: {
            message: 'Hashtag name is already taken.',
            url: '/v1/hashtags/check_hashtag_name',
            type: 'GET',
            delay: 1500     // Send Ajax request every 1.5 seconds
          }
        },
      },
      'hashtag[tag]': {
        validators: {
          notEmpty: {
            message: 'tag  is required'
          }
        },
      },
      'hashtag[amount]': {
        validators: {
          callback: {
            callback: function (value, validator, $field) {
              if ($('#hashtag_tag_type').val() != 0) {
                if ($('#hashtag_amount').val().length > 0) {
                  return {
                    valid: true,
                    //message: 'Valid number'
                  }
                } else {
                  return {
                    valid: false,
                    message: "amount is required"
                  }
                }
              } else {
                return { valid: true }
              }
            }
          }
        }
      },
      'hashtag[response]': {
        validators: {
          notEmpty: {
            message: ' '
          }
        }
      }
    }
  });

  // if hashtag isn't for payment, hide payment settings
  $('#hashtag_tag_type').change(function(){
    if (this.value == '0') {
      $('.hashtag-payment-settings').slideUp(200);
      $('#interval-settings').hide();
      $('#hashtag_amount').val('');
    } else {
      if (this.value == '1') {
        $('#interval-settings').hide();
      } else {
        $('#interval-settings').show();
      }
      $('.hashtag-payment-settings').slideDown(200);
    }
    $('#new_hashtag').formValidation('revalidateField', 'hashtag[amount]');
  }).change();
});
