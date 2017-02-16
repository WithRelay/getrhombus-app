var PriceSlider = new function() {

  var pricingSlider, priceValueSpan, amount, selection; //currentAmount,  
  var plans = { PlanA: { amt: 0, min: 0, max: 100 }, 
                PlanB: { amt: 50, min: 101, max: 1000 }, 
                PlanC: { amt: 75, min: 1001, max: 2500 }, 
                PlanD: { amt: 90, min: 2501, max: 5000 }, 
                PlanE: { amt: 105, min: 5001, max: 7500 }, 
                PlanF: { amt: 120, min: 7501, max: 10000 }, 
                PlanG: { amt: 145, min: 10001, max: 15000 }, 
                PlanH: { amt: 195, min: 15001, max: 20000 }, 
                PlanI: { amt: 240, min: 20001, max: 30000 }, 
                PlanJ: { amt: 295, min: 30001, max: 35000 }, 
                PlanK: { amt: 350, min: 35001, max: 40000 }, 
                PlanL: { amt: 400, min: 40001, max: 45000 }, 
                PlanM: { amt: 450, min: 45001, max: 50000 }, 
              };
  var keys = Object.keys(plans);

  this.bind_slider = function() {
    // show slider on merchant credit card info update form, show slider on pricing page load
    if ($('#pricing-range').length) {
      pricingSlider = document.getElementById('pricing-range');
      priceValueSpan = document.getElementById('price-value');
      $('.range-bar').remove();
      //currentAmount = (pricingSlider) ? pricingSlider.attributes.amountValue.value : 0;
      if (pricingSlider) {
        var slider = new Powerange(pricingSlider, {
          callback: displayValue, min: 100, max: 50000,
          start: 100, vertical: false, hideRange: true
        });
      };
    };
  };

  this.get_free_plan_name = function() {
    for(var i = 0, len = keys.length; i < len; i++) {
      if (plans[keys[i]].amt == 0) {
        return keys[i];
      }
    }
  };

  function displayValue() {
    selection = plan_range(pricingSlider.value);

    // also used by the credit_card_form_js to skip validation
    $('#plan_name').val(selection[0]);
    priceValueSpan.innerHTML = '<h4>' + selection[1] + '</h4>';

    // for add a subscription page
    if ($('#add_subscription').length) {
      if (pricingSlider.value <= 100) {
        $('#cc-fields').slideUp(300);
        $('#cc-submit').val('Get Started');
        $('#cc-form').data('formValidation').resetForm();
        $('#cc-number, #cc-ex-month, #cc-ex-year, #cc-uri, #cc-type, #cc-name, #cc-exp, #cc-csc').val("");
      } else {
        $('#cc-fields').slideDown(300);
        $('#cc-submit').val('Start 14-day Trial');
      };
    };

    /*
    # LEAVE THIS FOR LATER
    //only for subscription setting page
    if ($('#change_subscription_plan')[0]) {
      amount = plan_range(parseInt(pricingSlider.value))[2];
      submitValue = (amount > currentAmount) ?
        'Upgrade Subscription' :
        (amount < currentAmount) ? 'Downgrade Subscription' : 'Subscription';
      (submitValue === 'Subscription') ? $('#change_subscription_plan').hide() : $('#change_subscription_plan').val(submitValue).show();
      $('#pricing-range').val(plan_range(pricingSlider.value)[0]);
    } else {
      $('#select_plan').attr('href', '/users/sign_up?signup_plan=' + plan_range((pricingSlider.value)[0]));
    } 
    */
  };

  function plan_range(customerCount) {
    for(var i = 0, len = keys.length; i < len; i++) {
      if (customerCount >= plans[keys[i]].min && customerCount <= plans[keys[i]].max) {
        return [keys[i], planInfo(plans[keys[i]].amt)];
      };
    };
  };

  function planInfo(amount) {
    return '<h1 class="plan-amount">$'+ amount +'</h1><h5 class="signup-box-subheading starter-table">BILLED MONTHLY</h5>'
  };

};

$(document).ready(function() {
  PriceSlider.bind_slider(); 
});
