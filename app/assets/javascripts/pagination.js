// // js for show more feature with will_paginate gem
// jQuery(function() {
//
//   if ($('#with-button').size() > 0) {
//
//     $('.show_more').show().click(function() {
//       var more_plans_url = $('.next_page').attr('href');
//       var $this = $(this);
//       $this.button('loading');
//       $.getScript(more_plans_url)
//         .done(function(script) {})
//         .fail(function() {
//           flashError('Sorry we couldn\'t load more plans');
//         })
//         .always(function() {
//           $this.button('reset');
//         })
//     });
//   }
// });
$(document).ready(function(){
  if ($('.pagination').length) {
    $('.dashboard-body').scroll(function() {
      var url = $('.pagination .next_page a').attr('href')
        if (url && $('.dashboard-body').scrollTop() > $(document).height() - $('.dashboard-body').height() - 50) {
          $('.pagination').text("Fetching more...")
          return $.getScript(url);
        }
      });
    $('.dashboard-body').scroll();
  }
})
