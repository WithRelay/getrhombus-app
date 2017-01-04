$(document).ready(function() {
  var pricingSlider = document.getElementById('pricing-range'),
    currentAmount = (pricingSlider) ? pricingSlider.attributes.amountValue.value : 0,
    priceValueSpan = document.getElementById('price-value');

  if (pricingSlider) {
    var slider = new Powerange(pricingSlider, {
      callback : displayValue
      , decimal       : false
      , disableOpacity: 0.5
      , min           : 0
      , max           : 10000
      , start         : currentAmount
      , vertical      : true
    });

  }

  function displayValue() {
    // priceValueSpan.innerHTML = pricingSlider.value;
    priceValueSpan.innerHTML = '<h3><b> Amount: </b> $' + pricingSlider.value + '</h3><br>' +
      '<p>BILLED MONTHLY<p><br>' +
      '<h4>' + plan_range(pricingSlider.value)[1] + '</h4>';
    $('#select_plan').attr('href', '/signup?signup_plan=' + plan_range(pricingSlider.value)[0]);

    //only for subscription setting page
    if (changePlan = $('#change_subscription_plan')[0]) {
      changePlan.innerHTML = (parseInt(pricingSlider.value) > currentAmount) ?
        'Upgrage Subscription' :
        (parseInt(pricingSlider.value) < currentAmount) ? 'Downgrage Subscription' : 'Change Plan';
    }
  }

  function plan_range(amount) {
    if (amount > 0 && amount <= 100) {
      return ['starter_plan', 'Starter Plan for $0-$100/month']
    } else if (amount > 100 && amount <= 1000) {
      return ['growth_plan', 'Growth Plan for $101-$1,000/month']
    } else if (amount > 1000 && amount <= 5000) {
      return ['business_plan', 'Business Plan for $1,000-$5,000/month']
    } else if (amount > 5000 && amount <= 10000) {
      return ['enterprise_plan', 'Enterprise Plan for $5,001-$10,000/month']
    } else {
      return ['free_plan', 'Free Plan for $0/month']
    }
  }

});
