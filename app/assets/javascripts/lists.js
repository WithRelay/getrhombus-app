$(document).on('ready page:load', function() {

  $("#delete-lists").click(function(){
    var selectedUsers = getSelectedUserIds(); // why are you selecting users?

    if (selectedUsers.length < 1) {
      setFlashForList('Select a list to Delete', 'error');
    } else if (selectedUsers.length > 1) {
      setFlashForList('Only 1 list can be deleted at a time', 'error');
    }
    else {
      var selected_item = getSelectedUserIds();
      var id = 'list-delete-' + selected_item[0];
      FlashHandler.setConfirmationDialog(id,'Are you sure, you want to delete selected lists?', 'Delete', 'destroy-lists');
    }
  });

  $("#send-campaign-to-lists").click(function(){
    var selected_item = getSelectedUserIds();
    var link = $(this).data('lists-campaign');

    if (selected_item.length > 1) {
      return setFlashForList('Only 1 list can be selected for sending campaign', 'error');
    } else if (selected_item.length < 1) {
      return setFlashForList('Please select a list to send campaign', 'error');
    } else {
      var link_with_list_id = link + '?list_id=' + selected_item;
      window.location = link_with_list_id;
    };
  });

  // Toggles between checking or unchecking all checkboxes
  $("#check_or_uncheck_all").click(function(e){
    if ( $(this).is(':checked') ) {
      $('#create_list_button').removeAttr('disabled');
      $(".merchant_customers").prop('checked', true);
    } else {
      $('#create_list_button').attr('disabled', true);
      $(".merchant_customers").prop('checked', false);
    }
  });

  $('#Segment-Select-lists, #contacts-segment-list').on('change', function(e){
    if (this.value) {
      var window_location = window.location.pathname.split('/');
      window.location = '/' + window_location[1] + '/' + window_location[2]  + '/segments/' + this.value;
    };
  });

  $("#edit-selected-list").click(function(e){
    var selected_edit_list = getSelectedUserIds();

    if (selected_edit_list.length > 1) {
      return setFlashForList('Only 1 list can be selected for editing', 'error');
    } else if (selected_edit_list.length < 1) {
      return setFlashForList('Please select a list to edit', 'error');
    } else {
      var edit_list_form = $("#edit_list_form").attr("action").split('/');
      edit_list_form.pop();
      var list_name = $('.merchant_customers:checked').data("list-name");
      $("#edit-list-form").lightbox_me({
        centered: true,
        onLoad: function() {
          $('#edit-modal-list-name').val(list_name);
          $("#edit_list_form").attr("action", edit_list_form.join('/') + '/' + selected_edit_list[0]);
        },
        overlayCSS: {
          background: '#ffffff', opacity: .8
        }
      });
    }
  });

  // $('.merchant_customers').click(function(){
  //   $(this).is(':checked') && $('#create_list_button').removeAttr('disabled')
  //   $(':checkbox').not(this).attr('checked', false);
  // });

  $('.edit_create_user_list').formValidation({
    framework: 'bootstrap',
    live: 'disabled',
    err: {
      container: function($field, validator) {
        return $field.parent().find('.messageContainer');
      }
    },
    fields: {
      'lists[name]': {
        excluded: false,
        verbose: false,
        validators: {
          notEmpty: {
            message: 'List name is required'
          },
          remote: {
            url: '/v1/lists/check_list_name',
            type: 'GET'
          }
        }
      }
    }
  }).on('success.form.fv', function(e, data) {
    // Submission of the create list form
    $("form#create_user_list").submit(function(e){
      e.preventDefault();
      var action = $(this).attr('action');
      var method = $(this).attr('method');
      // Submit form via Ajax
      $.ajax({
        method: method,
        url: action,
        data: $(this).serializeArray(),
        dataType: 'json'
      }).done(function(msg){
        (msg.status == 404) && setFlashForList(msg.error.replace(/[\["\]']/g, ''), 'error');
        if (msg.status == 200){
          window.location = msg.redirect_url;
          setFlashForList('List successfully Created', 'notice');
          $('.close-modal').click();
        }
      }).fail(function(msg){
        setFlashForList('Unable to create list', 'error');
      });
    })
  });

  $('#segment-sidebar-form').formValidation({
    framework: 'bootstrap',
    live: 'disabled',
    err: {
      container: function($field, validator) {
        return $field.parent().find('.messageContainer');
      }
    },
    fields: {
      'number_of_days': {
        validators: {
          callback: {
            callback: function (value, validator, $field) {
              return { valid: ($field.val() > 0) };
            }
          }
        }
      },
    }
  }).on('success.form.fv', function(e) {
    e.preventDefault();
    $("#new-segment-div").lightbox_me({
      closeClick: true,
      closeEsc: true,
      centered: true,
      onLoad: function() {
        // Populate segment selection before submitting request
        $("#listChannel").val(getListChannel());
        $("#segment_create_modal").find('input:first');
        $("#segment_type").val($('#customer-filter option:selected').val());
        $("#segment_num_days").val($("#num_days").val());
        $("#segment_filter").val($('#days-filter option:selected').val());

        $("#additional_segment_type").val('customer_spend');
        $("#amt_filter").val($("#segment_filter_by option:selected").val());
        $("#lists_amt_1").val($("#amount_1").val());
        //$("#lists_amt_2").val($("#amount_2").val());
      },
      overlayCSS: {
        background: '#ffffff', opacity: .8
      }
    });
  });

  $('#create_segment').formValidation({
    framework: 'bootstrap',
    live: 'disabled',
    err: {
      container: function($field, validator) {
        return $field.parent().find('.messageContainer');
      }
    },
    fields: {
      'lists[segment_name]': {
        excluded: false,
        verbose: false,
        validators: {
          notEmpty: {
            message: 'segment name is required'
          },
          remote: {
            url: '/v1/lists/check_list_name',
            type: 'GET'
          }
        }
      }
    }
  }).on('success.form.fv', function(e) {
    e.preventDefault();
      var action = $(this).attr('action');
      var method = $(this).attr('method');
      var data = $(this).serializeArray();
      // Submit form via Ajax
      $.ajax({
        method: method,
        url: action,
        data: data,
        dataType: 'json'
      }).done(function(msg){
        $('.update-close-modals').click();
        setFlashForList('Segment created successfully', 'notice');
        // $('#segment-sidebar-form')[0].reset()
        // this.reset()
        location.reload()
      })
      .fail(function(msg){
        setFlashForList('Unable to create segment', 'error');
      })
  });

  // Fired when the user wants to select checkboxes that fall in a range
  jQuery(function($) {
    $('#merchant_customers').checkboxes('range', true);
  });

  // Fired on click on create list button
  $("#create_list_button").click(function(e) {
    if (!isAnyCheckboxSelected('.merchant_customers')) {
      setFlashForList('Please select customer from the table', 'error');
    } else {
      user_ids = getSelectedUserIds();
      $("#new-list-modal-div").lightbox_me({
        closeClick: true,
        closeEsc: true,
        centered: true,
        onLoad: function() {
          $("#selectedUsers").val(user_ids);
          $("#listCategory").val("list");
          $("#listType").val(getListType());
          $("#listChannel").val(getListChannel());
        },
        overlayCSS: {
          background: '#ffffff', opacity: .8
        }
      });
    }
    e.preventDefault();
  });

  function isAnyCheckboxSelected(checkbox_class){
    return $(checkbox_class).is(':checked') || $('#check_or_uncheck_all').is(':checked');
  }
  // On click of the cancel button close out the lightbox
  $(".cancel").click(function(e){
    $("#list_create_modal").hide();
    $("#segment_create_modal").hide();
  });

  function setFlashForList(msg, title){
    FlashHandler.setFlashMessage(msg, title);
  };

  function getSelectedUserIds(){
    var selected_users = []; // An array for storing selected users
    $('.merchant_customers:checked').each(function() {
      selected_users.push($(this).data('users'));
    });
    return selected_users;
  }

  $("#segment_filter_by").change(function(){
    checkBetweenSelected('#segment_filter_by', '#amount_2');
  });

  function checkBetweenSelected(element, hideShowField){
    if ($(element + ' option:selected').val() == 'between') {
      $(hideShowField).slideDown(100);
    } else {
      $(hideShowField).slideUp(100);
    };
  };

  function getListType() {
    return $("#list-data").data('list-type');
  };

  function getListID() {
    return $("#list-data").data('list-id');
  };

  function getListChannel() {
    return $("#list-data").data('list-channel');
  };

  $('.list-member-delete').click(function(e) {
    e.preventDefault();
    var id = $(this).parent().children()[0].id;
    FlashHandler.setConfirmationDialog(id, 'Are you sure you want to delete this member?', 'Delete', 'destroy-list-members');
  });

  $('.create-segment').click(function() {
    $('#listType').val(getListType());
  });

  var labelFieldSelectize = getListType() == 'contact' ? 'title' : ['email', 'description', 'card_name']
  $('.add-to-list-field').selectize({
    maxItems: 1,
    valueField: 'id',
    searchField: labelFieldSelectize,
    create: false,
    options: [],
    closeAfterSelect: true,
    render: {
      item: function(item, escape) {
        return '<div> <span class="">' + escape(item.title) + " - " + escape(item.description) + '</span></div>';
      },
      option: function(item, escape) {
        return '<div> <span class="">' + escape(item.title) + " - " + escape(item.description) + '</span></div>';
      }
    },
    load: function(query, callback) {
      var listURL = getListType() == 'contact' ? 'contacts' : 'customers';

      if (!query.length) return callback();
      $.ajax({
        url: '/v1/'+ listURL +'.json',
        type: 'GET',
        dataType: 'json',
        data: {
          query: query, list_id: getListID(), channel: getListChannel()
        },
        error: function() {
          FlashHandler.setFlashMessage('Something went wrong...Unable to find any ' + getListType(), 'error');
          callback();
        },
        success: function(res) {
          callback(res['data']);
        }
      });
    }
  });
});
