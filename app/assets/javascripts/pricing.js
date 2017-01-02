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
    step: 100,
    range: range_all_sliders
  });

  pricingSlider.noUiSlider.on('update', function ( values, handle ) {
    priceValueSpan.innerHTML = values[handle];
    $('#select_plan').attr('href', '/signup?signup_plan=' + values[handle])
  });

})
