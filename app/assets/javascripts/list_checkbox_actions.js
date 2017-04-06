$(document).ready(function(){

  $('.delete-resource').click(function(e){
    var statusName = campaignStatusName()
    if (statusName != "inactive"){
      FlashHandler.setConfirmationDialog('.delete-resource','Are you sure, you want to remove the ' + getCurrentURL(), 'Delete', 'isDestroy');
    }else if(statusName){
      FlashHandler.setFlashMessage( 'Inactive campaign cannot be deleted', 'error' );
    }
    else{
      showUncheckError();
    }
  });

  $('.deactivate-resource').click(function(e){
    var statusName = campaignStatusName()
    var text = { paused: 'Activate', active: 'Deactivate' }
    if (statusName != "inactive"){
      FlashHandler.setConfirmationDialog('.deactivate-resource','Are you sure, you want to '+ text[statusName] +' the campaign?', text[statusName], 'isDestroy');
    }
    else if(statusName){
      FlashHandler.setFlashMessage( 'Inactive campaign cannot be activate', 'error' );
    }
    else{
      showUncheckError();
    }
  });

  function showUncheckError(){
    FlashHandler.setFlashMessage( 'Please select campaign', 'error' );
  }

  function campaignStatusName(){
    return $('.checkboxes:checked').parent().find('.resource-status').text();
  }

  $(document).on('click', '.cancel-yes', function(e){
    if (getCurrentURL() == 'campaigns'){
      resource = new Resource(getResourceActionUrl());
      resource.updateOrDelete();
    }
  });

  function getResourceActionUrl(){
    if ($('.cancel-yes').text() == "Please wait...Delete"){
      action_url ='/v1/' + getCurrentURL() + '/'+ getSelectedCheckbox('.checkboxes') + '/delete_campaign/'
      return { 'url': action_url, 'method': 'delete' }
    }
      else{
        action_url = '/v1/' + getCurrentURL() + '/' + getSelectedCheckbox('.checkboxes') + '/change_status/'
        return { 'url': action_url, 'method': 'patch' }
      }
  }

  function getCurrentURL(){
    url = window.location.pathname.split('/');
    return url.pop();
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
      location.reload();
    }).fail(function(msg){ alert('Sorry request could not complete'); });
    $('.cancel-no').click();
  }
    else{
      FlashHandler.setFlashMessage( 'Please select and item you want to delete', 'error' );
      $('.cancel-no').click();
    }
  }
});
