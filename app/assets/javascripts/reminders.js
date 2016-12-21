$(document).on('ready page:load', function() {
  $('#new_reminder').formValidation({
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
      },
      'reminder[date_time]': {
        validators: {
          callback: {
            message: 'Date and Time should be 30 minutes greate than current date time',
            callback: function(value, validator, $field) {
              var selectedDateTime = $('#new_reminder').find('[name="reminder[date_time]"]').val();
              var momentDate = moment(selectedDateTime).toDate()
              var userDateTime = new Date(new Date().getTime() + 30*60000)
              console.log(momentDate)
              console.log(userDateTime)
              var x = moment.tz(momentDate, "America/New_York");
              console.log(x)
              return userDateTime < momentDate
            }
          }
        }
      }
    }
  }).on('change', function(e) {
    $('#new_reminder').formValidation('resetField', 'reminder[date_time]');
  });

  $( '#new_reminder' ).submit(function(e){
    e.preventDefault();
    var remoteCall = new RemoteCall(this)
    remoteCall.ajax()
  })
});

function RemoteCall(element){
  this.url = element.action;
  this.method = element.method;
  this.dataType = 'json';
  this.formData = $(element).serialize()
  this.domElementId = element.id
}
function checkFormValid(element){
  return $( '#' + element ).data('formValidation').isValid();
}
RemoteCall.prototype.ajax = function(){
  if (checkFormValid(this.domElementId)){
    $.ajax({ method: this.method,
             url: this.url,
             data: this.formData,
             dataType: 'json'
          }).done(function(msg){
              var flash_key = Object.keys(msg)[0]
              FlashHandler.setFlashMessage( msg[flash_key], flash_key )
          }).fail(function(msg){ alert(''); });
  }
}
