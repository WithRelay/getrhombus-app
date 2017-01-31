$(document).ready(function() {
  var pricingSlider, priceValueSpan, amount, currentAmount,
         free_plan_amount = 0,
         starter_plan_amount = 25,
         growth_plan_amount = 125,
         business_plan_amount = 250,
         enterprise_plan_amount = 400;

   // show slider on merchant credit card info update form
  // show slider on pricing page load
    if ($('#pricing-range')) {
      showSlider();
    }

   // show slider on subscription setting
   $('#setSubscription').on('focus', function (e) {
      showSlider();
    })


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
        , vertical      : false
      });
    }
  }

  function displayValue() {
    // priceValueSpan.innerHTML = pricingSlider.value;
    priceValueSpan.innerHTML = '<h5>' + pricingSlider.value + '<b> Users</b> </h5>' +
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
      return ['starter_plan', planInfo('Starter Plan', starter_plan_amount, 100), starter_plan_amount]
    } else if (customerCount > 100 && customerCount <= 1000) {
      return ['growth_plan',planInfo('Growth Plan', growth_plan_amount, 1000), growth_plan_amount]
    } else if (customerCount > 1000 && customerCount <= 5000) {
      return ['business_plan', planInfo('Business Plan', business_plan_amount, 5000), business_plan_amount]
    } else if (customerCount > 5000 && customerCount <= 10000) {
      return ['enterprise_plan', planInfo('Enterprise Plan', enterprise_plan_amount, 10000), enterprise_plan_amount]
    } else {
      return ['free_plan', planInfo('Free Plan', free_plan_amount, 0), free_plan_amount]
    }
  }

  function planInfo(plan, amount, count) {
    return '<h1 class="plan-amount">$'+ amount +'</h1><h5 class="signup-box-subheading starter-table">BILLED MONTHLY</h5><h5 class="signup-box-subheading">'+plan+' for $'+ amount +'/month Up to '+count+' Users</h5>'
  }

});
