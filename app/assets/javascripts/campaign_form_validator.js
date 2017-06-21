$(document).on('ready page:load', function() {
  
  var htmlContent = '<option value="0">SMS</option> <option value="1">MMS</option> <option value="3">Email</option>';
  var dropDownOption = { 'sms': [ '0', 'SMS'], 'messenger': ['2', 'Facebook Messenger'], 'email': ['3', 'Email'] };

  $( '#sendTestCampaign' ).click(function(e){
    e.preventDefault();
    $(this).attr('active', 'true')
    $( 'form#campaignForm' ).submit();
  });


  // review all these event handlers
  $("#trumbowyg").on('change', function(e) {
    $('#campaignForm').formValidation('resetField', 'campaign[text]');
    $('#campaignForm').formValidation('resetField', 'campaign[name]'); // is this needed?
  });

  $("#send-campaign-users").click(function(){
    $('#campaignForm').formValidation('resetField', 'campaign[text]');
    $('#campaignForm').formValidation('resetField', 'campaign[name]');
  });

  $('#campaign-channel').on('change', function(e) {
    $('#campaignForm').formValidation('resetField', 'campaign[name]');
    $('#campaignForm').formValidation('resetField', 'campaign[subject]');
  });

  // this is actually for campaigns not lists but uses lists
  // http://selectize.github.io/selectize.js/

  // For edit action, get lists data for preloading text input
  var x = $('#List'), campaign_lists = x.data("lists_data");

  // Can be undefined for new action
  campaign_lists = (campaign_lists) ? campaign_lists : [];
  var lists_selectize = x.selectize({
    valueField: 'id',
    labelField: 'name',
    searchField: 'name',
    openOnFocus: false,
    maxOptions: 5,
    maxItems: 1,
    create: false,
    options: campaign_lists,
    closeAfterSelect: true,
    render: {
      item: function(item, escape) {
        return '<div> <span class="name">' + escape(item.name) + '</span></div>';
      }
    },
    onItemRemove: function() { createDynamicDropdown(); },
    onItemAdd: function(value, $item) { createDynamicDropdown(lists_selectize[0].selectize.options[value]); },
    load: function(query, callback) {
      if (query.length < 2) return callback();
      $.ajax({
        url: window.location.protocol + "//" + window.location.host + "/v1/lists.json?query=" + encodeURIComponent(query),
        error: function() {
          FlashHandler.setFlashMessage('Something went wrong...Unable to find your lists', 'error');
          callback();
        },
        success: function(res) { 
          callback(res['lists']);
        }
      });
    }
  }).on('change', function(e) {
    $('#campaignForm').formValidation('resetField', 'campaign[list_name]');
  })

  function createDynamicDropdown(list_obj) {
    if (list_obj && list_obj.list_type == 'contact') {
      var listOption = dropDownOption[list_obj.channel];
      if (listOption) {
        var newHtmlContent = '<option value="'+ listOption[0] + '" >' +  listOption[1]  + "</option>";
        $('#campaign-channel').html(newHtmlContent);
      }
    } else {
      return $('#campaign-channel').html(htmlContent);
    }
    $('#campaign-channel').change();
  };

  // prefill form with previous lists
  $.each(campaign_lists, function (index, val) {
    lists_selectize[0].selectize.addItem(val['id']);
  });
});
