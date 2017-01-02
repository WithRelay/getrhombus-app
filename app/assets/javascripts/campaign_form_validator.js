$(document).on('ready page:load', function() {
  $('#new_campaign').formValidation({
    framework: 'bootstrap',
    excluded: ':disabled',
    live: 'disabled',
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
                return { valid: true }
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

  $("#trumbowyg").on('change', function(e) {
    $('#new_campaign').formValidation('resetField', 'campaign[text]');
  });


  // this is actually for campaigns not lists but uses lists
  // http://selectize.github.io/selectize.js/

  // For edit action, get lists data for preloading text input
  var x = $('#campaign-select-lists'),
  campaign_lists = x.data("lists_data");

  // Can be undefined for new action
  campaign_lists = (campaign_lists) ? campaign_lists : [];
  var lists_selectize = x.selectize({
    onItemRemove: function(){
      createDynamicDropdown();
    },
    onItemAdd: function(){
      var element = $('.selectize-input div').data();
      selectizeAjax(element.value);
    },
    onDropdownClose: function(){
      var element = $('.selectize-input div').data();
      if (element && element.value ==''){
          createDynamicDropdown();
      }
      else if ($('.selectize-input div').length == 0){
          createDynamicDropdown();
      }
    },
    valueField: 'id',
    labelField: 'name',
    searchField: 'name',
    openOnFocus: false,
    maxOptions: 5,
    maxItems: 1,
    options: campaign_lists,
    closeAfterSelect: true,
    render: {
      item: function(item, escape) {
        return '<div> <span class="name">' + escape(item.name) + '</span></div>';
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
        success: function(res) { createDynamicDropdown(res['lists']); callback(res['lists']); }
      });
    }
  }).on('change', function(e) {
    $('#new_campaign').formValidation('resetField', 'campaign[list_name]');
  })

  function selectizeAjax(listName){
    $.ajax({
      url: window.location.protocol + "//" + window.location.host + "/v1/lists.json?query=" + encodeURIComponent(listName),
      error: function() {
        FlashHandler.setFlashMessage('Something went wrong...Unable to find your lists', 'error');
        callback();
      },
      success: function(res) { createDynamicDropdown(res['lists']);}
    });
  }

  function createDynamicDropdown(list_name=''){
    var htmlContent = '<option value="0">SMS</option><option value="1">MMS</option> <option value="2">Facebook Messenger</option><option value="3">Email</option></select>'
    if (list_name.length > 0){
      var dropDownOption = { 'sms': [ '0', 'SMS'], 'messenger': ['2', 'Facebook Messenger'], 'email': ['3', 'Email'] };
      var listOption = dropDownOption[list_name[0].channel];
      if (listOption){
        var newHtmlContent = '<option value="'+ listOption[0] +'"'+ ">" +  listOption[1]  + "</option>";
        $('#campaign_channel').html(newHtmlContent);
      }
    }else{
      return $('#campaign_channel').html(htmlContent);
    }


  }

  // prefill form with previous lists
  $.each(campaign_lists, function (index, val) {
    lists_selectize[0].selectize.addItem(val['id']);
  });
});
