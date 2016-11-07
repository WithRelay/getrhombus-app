$(document).ready(function () {
  //  Hashtags, plans, coupons, Alerts
  var coupon_type_value  = $('#coupon-type-value');
  var coupon_type = $('#coupon-type');


  // no spaces
  $('#hashtag_tag, #coupon-name').on('input', function(){
    this.value = this.value.replace(/\s+/g, '');
  });

  // Positive integer only
  $('#interval-count, #duration-in-months, #max-redemptions, #subscription_quantity').on('input', function(){
    this.value = positive_integer_only(this.value);
  });

  function positive_integer_only(v) {
    return (v.match(/^[1-9]\d*$/)) ? v : v.slice(0, -1);
  }

  function positive_integer_less_than_100(v) {
    return (v.match(/^[1-9]\d*$/) && parseInt(v) < 101) ? v : v.slice(0, -1);
  }

  function decimal_with_up_to_two_places(v) {
    if (v.slice(-1) == '.' && (v.match(/[.]/g) || []).length == 1 && v.length > 1) return v
    // http://stackoverflow.com/questions/30606348/check-if-a-given-value-is-a-positive-number-or-float-with-maximum-two-decimal-pl
    // http://stackoverflow.com/questions/25053605/regex-to-allow-only-a-single-dot-in-a-textbox
    else if (v.match(/^\d+(.\d{1,2})?$/)) return v
    else return v.slice(0, -1);
  }

  // decimal with two places
  $('#hashtag_amount, #plan_amount').on('input', function(){
    $(this).val(function(_, v) {
      return decimal_with_up_to_two_places(v);
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

  coupon_type_value.on('input', function(){
    var v = this.value;
    this.value = (coupon_type.val() == 'amount_off') ? decimal_with_up_to_two_places(v) : positive_integer_less_than_100(v);
  });

  coupon_type.on('change', function() {
    var name_value = (this.value == 'amount_off') ? "coupon[amount_off]" : "coupon[percent_off]"
    coupon_type_value.val('').attr('name', name_value);
    $('#coupon-type-value-label').text(this.options[this.selectedIndex].text);
  });


});
