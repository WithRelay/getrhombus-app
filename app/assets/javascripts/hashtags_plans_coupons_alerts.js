$(document).ready(function () {

  //  Hashtags, plans, coupons, Alerts
  var coupon_type_value  = $('#coupon-type-value');
  var coupon_type = $('#coupon-type');
  var msg_emoji_box, emoji_area_text_length;

  // emojionearea
  if ($("#hashtag-response-textarea").length) {
    // for edit page - initialize count
    // emoji_area_text_length = (320 - $('#hashtag-response-textarea').val().length).toString() + " characters";
    // $('#char-count').text(emoji_area_text_length);

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
    })


    // paste - when you paste, keyup - so counter is more realtime
    // // emojibtn.click - as the name implies, blur - good measure, last resort, catch all
   msg_emoji_box[0].emojioneArea.on("blur paste keyup emojibtn.click", function(button, event) {
    //   emoji_area_text_length = 320 - msg_emoji_box[0].emojioneArea.getText().length;
    //   $('#char-count').text(emoji_area_text_length.toString() + " characters");
     })
    .on('change', function(e) {
      $('#new_hashtag').formValidation('resetField', 'hashtag[response]');
    });

  };

  // no spaces
  $('#hashtag_tag, #coupon-name').on('input', function(){ this.value = this.value.replace(/\s+/g, ''); });

  // Positive integer only
  $('#duration-in-months, #max-redemptions, #subscription_quantity').on('input', function(){
    this.value = positive_integer_only(this.value);
  });

  function positive_integer_only(v) { return (v.match(/^[1-9]\d*$/)) ? v : v.slice(0, -1); };

  function positive_integer_less_than_100(v) { return (v.match(/^[1-9]\d*$/) && parseInt(v) < 101) ? v : v.slice(0, -1); };

  function decimal_with_up_to_two_places(v) {
    if (v.slice(-1) == '.' && (v.match(/[.]/g) || []).length == 1 && v.length > 1) return v
    // http://stackoverflow.com/questions/30606348/check-if-a-given-value-is-a-positive-number-or-float-with-maximum-two-decimal-pl
    // http://stackoverflow.com/questions/25053605/regex-to-allow-only-a-single-dot-in-a-textbox
    else if (v.match(/^\d+(.\d{1,2})?$/)) return v
    else return v.slice(0, -1);
  };

  //disable checkbox
  $('.checkboxes').click(function(){
    if ($(this).is(':checked')){
      $('.checkboxes').attr('disabled', true);
      if ($('#activate-deactivate-campaign').length > 0){
          var statusName = $(this).parent().find('.resource-status').text();
          changeButtonName('#activate-deactivate-campaign', statusName)
      }
      $(this).attr('disabled', false);
    } else {
      $('.checkboxes').attr('disabled', false);
    };
  });

  function changeButtonName(buttonId, statusName){
    var status = { paused: '  Activate', active: '  Deactivate' }
    $(buttonId).text(status[statusName])
  }

  // decimal with two places
  $('#hashtag_amount, #Plan-Amount, #charge-amount').on('input', function(e){
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
            message: 'text is required'
          }
        }
      }
    }
  });

  // if hashtag isn't for payment, hide payment settings
  $('#hashtag_tag_type').change(function(){
    if (this.value == '0') {
      $('.hashtag-payment-settings').slideUp(200);
      $('#interval-settings').slideUp(200);
      $('#hashtag_amount').val('');
    } else {
      if (this.value == '1') {
        $('#interval-settings').slideUp(200);
      } else {
        $('#interval-settings').slideDown(200);
      }
      $('.hashtag-payment-settings').slideDown(200);
    }
    $('#new_hashtag').formValidation('revalidateField', 'hashtag[amount]');
  }).change();
});
