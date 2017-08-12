$(document).on('ready page:load', function() {

  // checked
  var htmlContent = '<option value="0">SMS</option> <option value="1">MMS</option> <option value="3">Email</option>';
  var dropDownOption = { 'sms': [ '0', 'SMS'], 'messenger': ['2', 'Facebook Messenger'], 'email': ['3', 'Email'] };
  // For edit action, get lists data for preloading text input
  var ajax_data, campaign_list_field = $('#campaign-list'), campaign_list = campaign_list_field.data("list-data");

  // checked
  $( '#sendTestCampaign' ).click(function(e) {
    e.preventDefault();
    $(this).attr('active', 'true');
    $( 'form#campaignForm' ).submit();
  });

  // checked-ish
  // review all these event handlers
  $("#trumbowyg").on('change', function(e) {
    $('#campaignForm').formValidation('resetField', 'campaign[text]');
    $('#campaignForm').formValidation('resetField', 'campaign[name]'); // is this needed?
  });

  // checked-ish
  $("#send-campaign-users").click(function() {
    $('#campaignForm').formValidation('resetField', 'campaign[text]');
    $('#campaignForm').formValidation('resetField', 'campaign[name]');
  });

  // checked-ish
  $('#campaign-channel').on('change', function(e) {
    $('#campaignForm').formValidation('resetField', 'campaign[name]');
    $('#campaignForm').formValidation('resetField', 'campaign[subject]');
  });

  function is_campaign_saved() {
    return $('#campaignForm').data('persisted');
  };

  function current_campaign_list_type() {
    return campaign_list[0].list_type;
  };

  function current_campaign_channel_is_email() {
    return $('#campaignForm').data('channel') == 'email';
  };

  // checked
  // http://selectize.github.io/selectize.js/
  // Can be undefined for new action
  campaign_list = (campaign_list) ? campaign_list : [];
  var lists_selectize = campaign_list_field.selectize({
    valueField: 'id',
    labelField: 'name',
    searchField: 'name',
    openOnFocus: false,
    maxOptions: 5,
    maxItems: 1,
    create: false,
    options: campaign_list,
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
      ajax_data = { query: encodeURIComponent(query) };

      // if campaign is already saved and has email channel, query for only customer-based list. contacts dont have emails
      // you could possibly restrict the list based on the channel of the existing campaign for sms/messenger too
      if (is_campaign_saved() && current_campaign_channel_is_email())
        ajax_data.list_type = current_campaign_list_type();

      $.ajax({
        url: window.location.protocol + "//" + window.location.host + "/v1/lists.json",
        data: ajax_data,
        success: function(res) { callback(res['lists']); console.log(res) },
        error: function() {
          FlashHandler.setFlashMessage('Something went wrong...Unable to find your lists', 'error');
          callback();
        }
      });
    }
  })

  $('#campaign-list-selectized').on('focus', function(){
    $('#campaignForm').formValidation('resetField', 'campaign[list_id]');
  })

  // checked
  function createDynamicDropdown(list_obj) {
    // you cannot change the channel of an existing campaign
    if (!is_campaign_saved()) {
      if (list_obj && list_obj.list_type == 'contact') {
        var listOption = dropDownOption[list_obj.channel];
        if (listOption) {
          var newHtmlContent = '<option value="'+ listOption[0] + '" >' +  listOption[1]  + "</option>";
          $('#campaign-channel').html(newHtmlContent);
        };
      } else {
        return $('#campaign-channel').html(htmlContent);
      }
    };
    $('#campaign-channel').change();
  };

  // checked
  // prefill form with previous lists
  $.each(campaign_list, function (index, val) {
    lists_selectize[0].selectize.addItem(val['id']);
  });


});
