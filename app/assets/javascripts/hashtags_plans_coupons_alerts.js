$(document).ready(function () {
  //  Hashtags, plans, coupons, Alerts

  var coupon_type_value  = $('#coupon-type-value'),
      coupon_type = $('#coupon-type');

  // no spaces
  $('#hashtag_tag, #coupon-name').on('input', function(){
    this.value = this.value.replace(/\s+/g, '');
  });

  // Positive integer only
<<<<<<< 5d128e9ddce52e8634c25887956473a3c1532ae3
<<<<<<< 8eae175802a3025763b4b07e8f0d7a7ac9f40dba
  $('#interval-count, #duration-in-months, #max-redemptions').on('input', function(){
=======
  $('#interval-count, #amount-off, #duration-in-months, #max-redemptions').on('input', function(){
>>>>>>> RHOMBUSV1-93 update coupon view, add check to emojionearea so it doesnt try to bind when div isnt available
=======
  $('#interval-count, #duration-in-months, #max-redemptions').on('input', function(){
>>>>>>> minor changes
    this.value = positive_integer_only(this.value);
  });

  coupon_type.on('change', function() {
    var name_value = (this.value == 'amount_off') ? "coupon[amount_off]" : "coupon[percent_off]"
    coupon_type_value.val('').attr('name', name_value);
    $('#coupon-type-value-label').text(this.options[this.selectedIndex].text);
  });

  coupon_type_value.on('input', function(){
    var v = this.value;
    this.value = (coupon_type.val() == 'amount_off') ? positive_integer_only(v) : positive_integer_less_than_100(v);
  });

  function positive_integer_only(v) {
    return (v.match(/^[1-9]\d*$/)) ? v : v.slice(0, -1);
  }

  function positive_integer_less_than_100(v) {
    return (v.match(/^[1-9]\d*$/) && parseInt(v) < 101) ? v : v.slice(0, -1);
  }

  // decimal with two places
  $('#hashtag_amount, #plan_amount').on('input', function(){
    $(this).val(function(_, v) {
      if (v.slice(-1) == '.' && (v.match(/[.]/g) || []).length == 1 && v.length > 1) return v
      // http://stackoverflow.com/questions/30606348/check-if-a-given-value-is-a-positive-number-or-float-with-maximum-two-decimal-pl
      // http://stackoverflow.com/questions/25053605/regex-to-allow-only-a-single-dot-in-a-textbox
      else if (v.match(/^\d+(.\d{1,2})?$/)) return v
      else return v.slice(0, -1);
    });
  });

  // if hashtag isn't for payment, remove payment settings
  $('#hashtag_tag_type').change(function(){
    if (this.value == '1') {
      $('#hashtag-payment-settings').slideUp(200);
      $('#interval-settings').slideUp(200);
    } else {
      (this.value == '3') ? $('#interval-settings').slideDown(200) : $('#interval-settings').slideUp(200);
      $('#hashtag-payment-settings').slideDown(200);
    }
  }).change();

  // if coupon isnt repeating. repeating needs length in months
  $('#coupon_duration').change(function(){
    if (this.value == 'repeating') {
      $('#duration-in-months-div').slideDown(200)
    } else {
      $('#duration-in-months-div').slideUp(200);
      $('#duration-in-months').val('');
    }
  }).change();

  $('#alert-include-sms').change(function(){
    (this.checked) ? $('#alert-sms-number').slideDown(200) : $('#alert-sms-number').slideUp(200);
  }).change();

});
