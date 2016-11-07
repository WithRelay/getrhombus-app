// js for show more feature with will_paginate gem
jQuery(function() {
  var loading_views;

  if ($('#with-button').size() > 0) {
    loading_views = false;
    $('.show_more').show().click(function() {
      var $this, more_plans_url;
      if (!loading_views) {
        loading_views = true;
        more_plans_url = $('.next_page').attr('href');
        $this = $(this);
        $this.button('loading');
          setTimeout(function() {
            $this.button('reset');
            $.getScript(more_plans_url, function() {
              if ($this) {
                $("html, body").animate({ scrollTop: $(document).height() }, 5000);
                $this.text('Show More').removeClass('disabled');
              }
              return loading_views = false;
            });
         }, 10);
      }
    });
  }
});
