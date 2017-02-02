$(document).ready(function(){

  $('#deleteResource').click(function(e){
    element = { 'checkBoxes': '.w-checkbox-input', 'hiddenField': '.w-hidden', 'url': '/v1/campaigns/delete' }
    resource = new Resource(element);
    resource.updateOrDelete();
  });

  $('#updateResource').click(function(){
    element = { 'checkBoxes': '.w-checkbox-input', 'hiddenField': '.w-hidden', 'url': '/v1/campaigns/change_status' }
    resource = new Resource(element);
    resource.updateOrDelete();
  });

  function Resource(element){
    var ids = []
    $.each($(element.checkBoxes + ':checkbox:checked'), function(index, value){
      ids.push($(value).next(element.hiddenField).text());
    });
    this.postData = ids;
    this.url = element.url;
  }

  Resource.prototype.updateOrDelete = function(){
    if (this.postData.length >= 1){
      $.ajax({ method: 'post',
              url: this.url,
              dataType: 'Json',
              data: { 'ids': this.postData }
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
