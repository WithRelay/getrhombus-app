$(document).on('ready page:load', function() {
  $('#reminderForm').formValidation({
    framework: 'bootstrap',
    excluded: ':disabled',
    live: 'disabled',
    fields: {
      'reminder[channel]': {
        validators: {
          notEmpty: {
            message: 'Campaign name is required'
          }
        }
      },
      'reminder[text]': {
        validators: {
          notEmpty: {
            message: 'This Field is required'
          }
        }
      }
    }
  }).on('success.form.fv', function(e, data) {
        e.preventDefault();
        var apiController = new ApiController(this, '#myModalNorm');
        var formData = new FormData(this);
        apiController.sendRequest(formData)
    });
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
