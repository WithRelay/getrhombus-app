var CheckedItem = new function() {
  this.get = function() {
    var selectedElement = false;
    $('.table-checkbox' + ':checkbox:checked').each(function(index, element) {
      selectedElement = $(this);
      return false;
    });
    return selectedElement;
  };

  this.process = function(confirmBtnText, selector, isConfirm) {
    var yes_button = $('.cancel-yes').html('Please wait...'), obj_type = CheckedItem.obj_type();
    console.log(selector)

    if (['plan', 'coupon', 'fb_page', 'list-members', 'segment'].indexOf(obj_type) > -1) {
      if (isConfirm) $(selector).attr(isConfirm, true);
      $(selector)[0].click();
      return;
    };

    var selectedElement = CheckedItem.get();
    if (!selectedElement) return false;
      
    if (obj_type == 'campaign') {
      var msg = yes_button.parent().find('p').text(),
      resource = new Resource(getCampaignActionUrl(selectedElement, msg));
      resource.updateOrDelete();
    } else if ((obj_type == 'hashtag' && confirmBtnText.toLowerCase().indexOf('change') > -1) || obj_type == 'transaction') {
      selectedElement.parents('.edit_' + obj_type).submit();
    } else {
      if (isConfirm) $(selector).attr(isConfirm, true);
      $(selector)[0].click();
    };
  };

  this.obj_type = function() {
    return $('#objlists').data('object-type');
  };

  function getCampaignActionUrl(selectedElement, msg) {
    var checked_item_id = selectedElement.parent().find('.resource-id').text();

    if (/delete/i.test(msg))
      return { id: checked_item_id, 'url': '/v1/campaigns/' + checked_item_id + '/delete_campaign/', 'method': 'delete' };
    else
      return { id: checked_item_id, 'url': '/v1/campaigns/' + checked_item_id + '/change_status/', 'method': 'patch' };
  };

  function Resource(element) {
    this.postData = element.id;
    this.url = element.url;
    this.method = element.method;
  };

  Resource.prototype.updateOrDelete = function() {
    if (this.postData != undefined) {
      $.ajax({
        method: this.method,
        url: this.url,
        dataType: 'json',
        data: { 'id': this.postData }
      }).done(function(data) {
        FlashHandler.setFlashMessage(data.notice, 'notice');
        location.reload();
      })
      .fail(function(msg){
        FlashHandler.setFlashMessage('Unable to complete request', 'error');
        $('.cancel-no').click();
      });
    } else {
      FlashHandler.setFlashMessage('Please select and item you want to update/delete', 'error');
      $('.cancel-no').click();
    }
  };
};

// used by several index pages
$(document).on("click", ".checkboxes", function() {
  if ($(this).is(':checked')) {
    $('.checkboxes').attr('disabled', true);

    // campaign, hashtag index pages specific
    if ($('#activate-deactivate-campaign').length > 0) {
      var statusName = $(this).parent().find('.resource-status').text();
      var status = { paused: ' Activate', active: ' Pause', inactive: ' Activate' };
      $('#activate-deactivate-campaign').text(status[statusName]);
    } else if ($('#deactivate-hashtag').length) {
      var statusName = $(this).parent().find('.resource-status').val();
      var status = { active: ' <strong>Activate</strong>', inactive: ' <strong>Deactivate</strong>' };
      $('#deactivate-hashtag').html(status[statusName]);
    };

    $(this).attr('disabled', false);
  } else {
    $('.checkboxes').attr('disabled', false);
  };
});

$(document).on('click', '.cancel-no', function(e){
  $('.cancel-subscription-wrapper').trigger('close');
});
