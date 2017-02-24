$( document ).ready(function() {
  "use strict";
  var index = 1;
  if ($('#select_page').length > 0){
    check_status($('#select_page').val().split(' ')[index]);
    $( '#Select-Facebook-Page' ).change(function() {
      check_status($(this).val().split(' ')[index]);
    });
  }

  $('#select_page').click(function (evt) {
    if (($(this).val() === 'Subscribe') && (!$(this).attr('subscribed_page'))) {
      if (!$(this).attr('canSubscribe')) {
        FlashHandler.setConfirmationDialog('#select_page',
          'Conversations linked to your Facebook page being synced to your business app integrations. Continue?', 'Subscribe', 'canSubscribe' );
        return false;
      }

    }
    else if (($(this).val() === 'Subscribe') && ($(this).attr('subscribed_page'))) {
      if (!$(this).attr('canSubscribe')) {
        FlashHandler.setConfirmationDialog('#select_page',
          'Existing conversations linked to your previous Facebook page will stop being synced to your business app integrations. Continue?', 'Subscribe', 'canSubscribe' );
        return false;
      }

    }
    else if(($(this).val() === 'Unsubscribe')){
      if (!$(this).attr('canUnsubscribe')) {
        FlashHandler.setConfirmationDialog('#select_page',
          'Existing conversations linked to this Facebook page will stop being synced to your business app integrations. Continue?', 'Unsubscribe', 'canUnsubscribe' );
        return false;
      }
    }
  });

  $('#delete_integration').click(function (evt) {
    if (!$('#delete_integration').attr('isDestroy')) {
      FlashHandler.setConfirmationDialog('#delete_integration',
        'Are you sure, you want to remove the Messenger integration?', 'Remove Integration', 'isDestroy' );
      return false;
    }
  });

  // validate link_facebook form
    $('#user_login_form')
      .formValidation({
        framework: 'bootstrap',
        live: 'disabled',
        fields: {
            'email': {
                  verbose: false,
                  row: '.group',
                  validators: {
                      notEmpty: {
                          message: 'Your email is required'
                      },
                      emailAddress: {
                          message: "The email isn't valid"
                      },
                      remote: {
                          type: 'GET',
                          url: 'https://api.mailgun.net/v2/address/validate?callback=?',
                          crossDomain: true,
                          name: 'address',
                          data: {
                              // Registry a Mailgun account and get a free API key
                              // at https://mailgun.com/signup
                              api_key: '<redacted_api_key>'
                          },
                          dataType: 'jsonp',
                          validKey: 'is_valid',
                          message: "The email isn't exists"
                      }
                  }
              },
            'password': {
                row: '.group',
                validators: {
                    notEmpty: {
                        message: 'Password  is required'
                    }
                }
              }
          }
        })
       .on('err.validator.fv', function(e, data) {
          if (data.field === 'email' && data.validator === 'remote') {
              // We need to reset the error message
              data.element                // The field element
                  .data('fv.messages')    // The message container
                  .find('[data-fv-validator="remote"][data-fv-for="email"]')
                  .html("The email isn't valid")
                  .show();
          }
      });

   $('#remove_twitter_integration').click(function (evt) {
     if (!$('#remove_twitter_integration').attr('isDestroy')) {
       FlashHandler.setConfirmationDialog('#remove_twitter_integration',
         'Are you sure, you want to remove the twitter integration?', 'Remove Integration', 'isDestroy' );
       return false;
     }
   });

   $('#remove_stripe_integration').click(function (evt) {
     if (!$('#remove_stripe_integration').attr('isDestroy')) {
       FlashHandler.setConfirmationDialog('#remove_stripe_integration',
         'Are you sure, you want to remove the stripe integration?', 'Remove Integration', 'isDestroy' );
       return false;
     }
   });

   function check_status(val){
     if (!val) {
       $('#select_page').hide();
     }
     else if (val === 'false'){
       $('#select_page').show();
       $('#select_page').val('Subscribe');
       $('#select_page').attr('class', 'button w-button')
     }
     else{
       $('#select_page').show();
       $('#select_page').val('Unsubscribe');
       $('#select_page').attr('class', 'button w-button')
     }
   }

});
