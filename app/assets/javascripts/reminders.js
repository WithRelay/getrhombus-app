$(document).on('ready page:load', function() {

  $('#reminder-customer-list').selectize({
    maxItems: 1,
    valueField: 'uid',
    labelField: 'title',
    searchField: 'description',
    create: false,
    options: [],
    closeAfterSelect: true,
    load: function(query, callback) {
      if (!query.length) return callback();
      $.ajax({
        url: '/v1/users.json',
        type: 'GET',
        dataType: 'json',
        data: {
          query: query
        },
        error: function() {
          FlashHandler.setFlashMessage('Something went wrong...Unable to find any customer', 'error');
          callback();
        },
        success: function(res) {
          callback(res['data']);
        }
      });
    }
  });

  $('#delete-reminder').click(function(e){
      e.preventDefault
      FlashHandler.setConfirmationDialog('#delete-reminder','Are you sure, you want to delete the Reminder?', 'Delete', 'isDistroy');

      return false;
    });

  $('#submitReminderForm').click(function(){
    $('#reminderForm').formValidation('resetField', 'reminder[text]');
    $('#reminderForm').submit();
  });

  $('#Notification-Message').emojioneArea();

  $('#reminderForm').formValidation({
    framework: 'bootstrap',
    excluded: ':disabled',
    live: 'disabled',
    fields: {
      'reminder[text]': {
        validators: {
          notEmpty: {
            message: 'This Field is required'
          }
        }
      }
    }
  }).on('success.form.fv', function(e, data) {
    alert('s')
        e.preventDefault();
        var apiController = new ApiController(this, '#myModalNorm');
        var formData = new FormData(this);
        apiController.sendRequest(formData)
    });






// Class ApiController handle all call to http verb to the server
// First argument is the dom object it self and second contains the modal id
function ApiController(element, modalId = ''){
  // assigning properties to RemoteCall
  this.url = element.action;
  this.method = element.method;
  this.dataType = 'json';
  this.domElementId = '#' + element.id;
  this.modalId = modalId;
  this.formData = $(element).serialize();
}
// Checks whether the form is validated or not and return true/false
function checkFormValid(element){
  return $(element ).data('formValidation').isValid();
}
// defining instance method sendRequest for class ApiController
// Send remote request and fetch response.
ApiController.prototype.sendRequest = function(data=''){
  // assigning modal class for closing modal after response success
  // The variable has sigil $ beacause local variable inside ajax call are not accessible.
  // for more deails http://stackoverflow.com/questions/14496680/this-object-not-available-in-ajax-callback
  var postData = ((data !='') ? data : this.formData)
  var $modalClose = this.modalId + ' .close'
  if (checkFormValid(this.domElementId)){
    $.ajax({ method: this.method,
             url: this.url,
             contentType: false,
             processData: false,
             dataType: this.dataType,
             data: postData
          }).done(function(msg){
              // key in index 1 contains title/flash message key please see api/controllers/reminders for more details.
              var flash_key = Object.keys(msg)[1]
              // set flash message title and message
              // first argument is title and second is text message.
              FlashHandler.setFlashMessage( msg[flash_key], flash_key );
              if (flash_key!='error'){
                $($modalClose).click()// closing modal after succession
              }
          }).fail(function(msg){ alert('Sorry request could not complete'); });
  }
}
});
