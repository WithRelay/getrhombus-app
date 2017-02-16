$(document).ready(function() {
  var pricingSlider, priceValueSpan, amount, selection,//currentAmount,
      PlanA = 0,
      PlanB = 50,
      PlanC = 75,
      PlanD = 90,
      PlanE = 105,
      PlanF = 120,
      PlanG = 145,
      PlanH = 195,
      PlanI = 240,
      PlanJ = 295,
      PlanK = 350,
      PlanL = 400,
      PlanM = 450,
      PlanN = 500;

  // show slider on merchant credit card info update form
  // show slider on pricing page load
  if ($('#pricing-range')) {
    showSlider();
  };

  function showSlider(){
    pricingSlider = document.getElementById('pricing-range');
    priceValueSpan = document.getElementById('price-value');
    $('.range-bar').remove();
    //currentAmount = (pricingSlider) ? pricingSlider.attributes.amountValue.value : 0;
    if (pricingSlider) {
      var slider = new Powerange(pricingSlider, {
        callback : displayValue
        , min           : 100
        , max           : 50000
        , start         : 100
        , vertical      : false
        , hideRange     : true
      });
    }
  }

  function displayValue() {
    selection = plan_range(pricingSlider.value)
    priceValueSpan.innerHTML = '<h4>' + selection[1] + '</h4>';

    // for add a subscription page
    if ($('#add_subscription').length) {
      if (pricingSlider.value <= 100) {
        $('#cc-fields').slideUp(300);
        $('#add_subscription_btn').val('Get Started');
      } else {
        $('#cc-fields').slideDown(300);
        $('#add_subscription_btn').val('Start 14-day Trial');
      }
    }

    $('#plan_name').val(selection[0])
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
    }
    else {
      $('#select_plan').attr('href', '/users/sign_up?signup_plan=' + plan_range((pricingSlider.value)[0]));
    } 
    */
  }

  function plan_range(customerCount) {
    if (customerCount > 0 && customerCount <= 100) {
      return ['PlanA', planInfo(PlanA)]
    } else if (customerCount > 101 && customerCount <= 1000) {
      return ['PlanB', planInfo(PlanB)]
    } else if (customerCount > 1001 && customerCount <= 2500) {
      return ['PlanC',planInfo(PlanC)]
    } else if (customerCount > 2501 && customerCount <= 5000) {
      return ['PlanD', planInfo(PlanD)]
    } else if (customerCount > 5001 && customerCount <= 7500) {
      return ['PlanE', planInfo(PlanE)]
    } else if (customerCount > 7501 && customerCount <= 10000) {
      return ['PlanF',planInfo(PlanF)]
    } else if (customerCount > 10001 && customerCount <= 15000) {
      return ['PlanG', planInfo(PlanG)]
    } else if (customerCount > 15000 && customerCount <= 20000) {
      return ['PlanH', planInfo(PlanH)]
    } else if (customerCount > 20001 && customerCount <= 30000) {
      return ['PlanI',planInfo(PlanI)]
    } else if (customerCount > 30001 && customerCount <= 35000) {
      return ['PlanJ', planInfo(PlanJ)]
    } else if (customerCount > 30001 && customerCount <= 35000) {
      return ['PlanK', planInfo(PlanK)]
    } else if (customerCount > 35001 && customerCount <= 40000) {
      return ['PlanL',planInfo(PlanL)]
    } else if (customerCount > 40001 && customerCount <= 45000) {
      return ['PlanM', planInfo(PlanM)]
    } else {
      return ['PlanN', planInfo(PlanN)]
    }
  }

  function planInfo(amount) {
    return '<h1 class="plan-amount">$'+ amount +'</h1><h5 class="signup-box-subheading starter-table">BILLED MONTHLY</h5>'
  }

});
