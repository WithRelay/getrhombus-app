$(document).on('ready page:load', function() {
  $('#new_campaign').formValidation({
    framework: 'bootstrap',
    excluded: ':disabled',
    live: 'disabled',
    // excluded: [ ':hidden', ':not(:visible)' ],
    fields: {
      'campaign[name]': {
        validators: {
          notEmpty: {
            message: 'Campaign name is required'
          },
          remote: {
            message: 'Campaign name already taken.',
            url: '/v1/campaigns/check_campaign_name',
            type: 'POST'
          }
        }
      },
      'campaign[subject]': {
        validators: {
          callback: {
            callback: function (value, validator, $field) {
              if ($('#campaign_channel').val() == 3) {
                if ($('#campaign_subject').val().length > 0) {
                  return {
                    valid: true, 
                    //message: 'Valid number'
                  }
                } else {
                  return {
                    valid: false,
                    message: "Subject is required"
                  }
                }
              } else {
                return { 
                  valid: true 
                }
              }
            }
          }
        }
      },
      'campaign[list_name]': {
        validators: {
          notEmpty: {
            message: 'This Field is required'
          }
        }
      },
      'campaign[text]': {
        validators: {
          notEmpty: {
            message: 'This Field is required'
          }
        }
      }
    }
  });

  $("#trumbowyg").on('keyup', function(e) {
    $('#new_campaign').formValidation('resetField', 'campaign[text]');
  });

  // bind emoji to textarea
  /*var reply_body_emoji_box = $('#saved-reply-body-field').emojioneArea({
    pickerPosition: 'bottom',
  });


  function set_title_and_body() {
    $('#saved-reply-title-field').val($('#saved-reply-title-' + id).text());
    reply_body_emoji_box[0].emojioneArea.setText($('#saved-reply-body-' + id).text());
  }*/

  /*$('#trumbowyg')[0].emojioneArea.events: {
    /**
     * @param {jQuery} editor EmojioneArea input
     * @param {Event} event jQuery Event object
     */
   /* focus: function (editor, event) {
      console.log('event:focus');
    }setText($('#saved-reply-body-' + id).text());
    */ 

  $("#trumbowyg").emojioneArea({
  events: {
    /**
     * @param {jQuery} editor EmojioneArea input
     * @param {Event} event jQuery Event object
     */
    focus: function (editor, event) {
      console.log('event:focus');
    }
  }
})


  // this is actually for campaigns not lists but uses lists
  // http://selectize.github.io/selectize.js/

  // For edit action, get lists data for preloading text input
  var x = $('#campaign-select-lists'),
  campaign_lists = x.data("lists_data");

  // Can be undefined for new action
  campaign_lists = (campaign_lists) ? campaign_lists : [];
  var lists_selectize = x.selectize({
    valueField: 'id',
    labelField: 'name',
    searchField: 'name',
    openOnFocus: false,
    maxOptions: 5,
    options: campaign_lists,
    closeAfterSelect: true,
    render: {
      item: function(item, escape) {
        return '<div> <span class="name">' + escape(item.name) + '</span></div>';
      },
      option: function(item, escape) {
        return '<div><span class="label">' + escape(item.name) + '</span></div>';
      }
    },
    load: function(query, callback) {
      if (query.length < 2) return callback();
      $.ajax({
        url: window.location.protocol + "//" + window.location.host + "/v1/lists.json?query=" + encodeURIComponent(query),
        error: function() {
          FlashHandler.setFlashMessage('Something went wrong...Unable to find your lists', 'error');
          callback();
        },
        success: function(res) { callback(res['lists']); }
      });
    }
  });

  // prefill form with previous lists
  $.each(campaign_lists, function (index, val) {
    lists_selectize[0].selectize.addItem(val['id']);
  });
});
