// // js for show more feature with will_paginate gem
jQuery(function() {

  if ($('#with-button').size() > 0) {

    $('.show_more').show().click(function() {
      var more_items_url = $('.next_page').attr('href');
      var $this = $(this);
      var content = $this.html();
      var data_loading_text = $this.attr('data-loading-text');
      $this.text(data_loading_text);
      $.getScript(more_items_url)
        .done(function(script) {})
        .fail(function() {
          FlashHandler.setFlashMessage('Sorry we couldn\'t load more items', 'error');
        })
        .always(function() {
          $this.html(content);
        })
    });
  }
});
