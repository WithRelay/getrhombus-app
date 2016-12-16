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
      // 'campaign[subject]': {
      //   enable: $('#campaign_channel').val()== 3,
      //   validators: {
      //     notEmpty: {
      //       message: 'Subject is required'
      //     }
      //   }
      // },
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
  })  .on('change', function(e) {
      $('#new_campaign').formValidation('resetField', 'campaign[text]');
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
  })
  .on('change', function(e) {
    $('#new_campaign').formValidation('resetField', 'campaign[list_name]');
  })
  $( "#click-me" ).click(function() {
    alert(lists_selectize[0].selectize.getValue())
  });

  // prefill form with previous lists
  $.each(campaign_lists, function (index, val) {
    lists_selectize[0].selectize.addItem(val['id']);
  });
});
