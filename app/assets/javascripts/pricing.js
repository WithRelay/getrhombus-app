$(document).ready(function () {
  var pricingSlider = document.getElementById('pricing-range'),
         priceValueSpan = document.getElementById('price-value'),
         range_all_sliders = {
                                                  'min': 0,
                                                  '10%': 100,
                                                  '25%': 1000,
                                                  '50%': 5000,
                                                  'max': 10000
                                                };

  noUiSlider.create(pricingSlider, {
    start: [0],
    connect: [true, false],
    orientation: 'horizontal',
    step: 100,
    range: range_all_sliders
  });

  pricingSlider.noUiSlider.on('update', function ( values, handle ) {
    priceValueSpan.innerHTML = '<h3><b> Amount: </b>'+ values[handle] +'</h3><br>' +
                                                        '<h4>'+plan_range(values[handle])[1]+'</h4>';
    $('#select_plan').attr('href', '/signup?signup_plan=' + plan_range(values[handle])[0]);
  });

  function plan_range(amount){
    if (amount > 0 && amount <= 100){
      return ['starter_plan', 'Starter Plan for $0-$100/month']
    } else if (amount > 100 && amount <= 1000){
      return ['growth_plan', 'Growth Plan for $101-$1,000/month']
    } else if (amount > 1000 && amount <= 5000){
      return ['business_plan', 'Business Plan for $1,000-$5,000/month']
    } else if (amount > 5000 && amount <= 10000){
      return ['enterprise_plan', 'Enterprise Plan for $5,001-$10,000/month']
    } else {
      return ['free_plan', 'Free Plan for $0/month']
    }
  }
})
