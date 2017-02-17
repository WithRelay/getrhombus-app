$(document).ready(function(){

  $('.delete-resource').click(function(e){
    FlashHandler.setConfirmationDialog('.delete-resource','Are you sure, you want to remove the ' + getCurrentURL(), 'Delete', 'isDestroy');
  });

  $('.deactivate-resource').click(function(e){
    FlashHandler.setConfirmationDialog('.deactivate-resource','Are you sure, you want to deactivate the campaign?', 'Deactivate', 'isDestroy');
  });

  $(document).on('click', '.cancel-yes', function(e){
    if (getCurrentURL() == 'campaigns'){
      resource = new Resource(getResourceActionUrl());
      resource.updateOrDelete();
    }
  });

  function getResourceActionUrl(){
    if ($('.cancel-yes').text() == 'Please wait...Deactivate'){
      action_url = '/v1/' + getCurrentURL() + '/change_status/' + getSelectedCheckbox('.checkboxes')
      return { 'url': action_url, 'method': 'patch' }
    }
      else{
        action_url ='/v1/' + getCurrentURL() + '/delete/' + getSelectedCheckbox('.checkboxes')
        return { 'url': action_url, 'method': 'delete' }
      }
  }

  function getCurrentURL(){
    url = window.location.pathname.split('/');
    return url[url.length-1]
  }

  function getSelectedCheckbox(checkbox_class){
    var resource_id;
    $(checkbox_class).each(function( index, element){
       if ($(this).is(':checked')){
         resource_id= $(this).parent().find('.resource-id').text();
       }
     });
     return resource_id
  }

  function Resource(element){
    var id
    $.each($('.table-checkbox' + ':checkbox:checked'), function(index, value){
      if ($(this).is(':checked')){
        id =  $(this).parent().find('.resource-id').text()
      }
    });
    this.postData = id;
    this.url = element.url;
    this.method = element.method;
  }

  Resource.prototype.updateOrDelete = function(){
    if (this.postData != undefined){
      $.ajax({ method: this.method,
              url: this.url,
              dataType: 'Json',
              data: { 'id': this.postData }
    }).done(function(msg){
      // key in index 1 contains title/flash message key please see api/controllers/reminders for more details.
      var flash_key = Object.keys(msg)[1]
      // set flash message title and message
      // first argument is title and second is text message.
      FlashHandler.setFlashMessage( msg[flash_key], flash_key );
    }).fail(function(msg){ alert('Sorry request could not complete'); });
    $('.cancel-no').click();
  }
    else{
      FlashHandler.setFlashMessage( 'Please select and item you want to delete', 'error' );
      $('.cancel-no').click();
    }
  }
});
