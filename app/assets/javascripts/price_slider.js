$(document).ready(function() {
  var pricingSlider, priceValueSpan, amount, currentAmount,
         free_plan_amount = 0,
         starter_plan_amount = 55,
         growth_plan_amount = 255,
         business_plan_amount = 2500,
         enterprise_plan_amount = 7000;

  // show slider on pricing page load
  $(function(){
    if (location.pathname === "/pricing") {
      showSlider();
    }
  });

   // show slider on subscription setting
   $('#setSubscription').on('focus', function (e) {
      showSlider();
    })

   // show slider on merchant credit card info update form
   $(function(){
     if (location.pathname === "/profile") {
       showSlider();
     }
   });

  function showSlider(){
    pricingSlider = document.getElementById('pricing-range');
    priceValueSpan = document.getElementById('price-value');
    $('.range-bar').remove();
    currentAmount = (pricingSlider) ? pricingSlider.attributes.amountValue.value : 0;
    if (pricingSlider) {
      var slider = new Powerange(pricingSlider, {
        callback : displayValue
        , decimal       : false
        , hideRange     : true
        , disableOpacity: 0.5
        , min           : 0
        , max           : 10000
        , start         : 0
        , vertical      : true
      });
    }
  }

  function displayValue() {
    // priceValueSpan.innerHTML = pricingSlider.value;
    priceValueSpan.innerHTML = '<h3>' + pricingSlider.value + '<b> Users</b> </h3><br>' +
      '<p>BILLED MONTHLY<p><br>' +
      '<h4>' + plan_range(pricingSlider.value)[1] + '</h4>';

    //only for subscription setting page
    if ($('#change_subscription_plan')[0]) {
      amount = plan_range(parseInt(pricingSlider.value))[2];
      submitValue = (amount > currentAmount) ?
        'Upgrade Subscription' :
        (amount < currentAmount) ? 'Downgrade Subscription' : 'Subscription';
      (submitValue === 'Subscription') ? $('#change_subscription_plan').hide() : $('#change_subscription_plan').val(submitValue).show();
      $('#pricing-range').val(plan_range(pricingSlider.value)[0]);
    }
    else {
      // $('#select_plan').attr('href', '/signup?signup_plan=' + plan_range(pricingSlider.value)[0]);
      // update selected plan name
      $('#pricing-range').val(plan_range(pricingSlider.value)[0]);
    }
  }

  function plan_range(customerCount) {
    if (customerCount > 0 && customerCount <= 100) {
      return ['starter_plan', 'Starter Plan for $55/month <br>Up to 100 Users', starter_plan_amount]
    } else if (customerCount > 100 && customerCount <= 1000) {
      return ['growth_plan', 'Growth Plan for $255/month <br>Up to 1000 Users', growth_plan_amount]
    } else if (customerCount > 1000 && customerCount <= 5000) {
      return ['business_plan', 'Business Plan for $2500/month <br>Up to 5000 Users', business_plan_amount]
    } else if (customerCount > 5000 && customerCount <= 10000) {
      return ['enterprise_plan', 'Enterprise Plan for $7000/month <br>Up to 10,000+ Users', enterprise_plan_amount]
    } else {
      return ['free_plan', 'Free Plan for $0/month <br>Up to 0 Users', free_plan_amount]
    }
  }

});
