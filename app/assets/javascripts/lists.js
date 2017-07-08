$(document).on('ready page:load', function() {

  $("#delete-lists").click(function(){
    var selected_objects = getSelectedObjectIds();

    if (selected_objects.length < 1) {
      setFlashForList('Select a list to Delete', 'error');
    } else if (selected_objects.length > 1) {
      setFlashForList('Only 1 list can be deleted at a time', 'error');
    } else {
      var id = '#list-delete-' + selected_objects[0];
      FlashHandler.setConfirmationDialog(id, 'Are you sure you want to delete the selected list?', 'Delete', 'destroy-lists');
    };
  });

  $("#send-campaign-to-lists").click(function(){
    var selected_objects = getSelectedObjectIds();
    var link = $(this).data('lists-campaign');

    if (selected_objects.length > 1) {
      return setFlashForList('Only 1 list can be selected for sending campaign', 'error');
    } else if (selected_objects.length < 1) {
      return setFlashForList('Please select a list to send campaign', 'error');
    } else {
      var link_with_list_id = link + '?list_id=' + selected_objects[0];
      window.location = link_with_list_id;
    };
  });

  // Toggles between checking or unchecking all checkboxes
  $("#check_or_uncheck_all").click(function(e){
    if ( $(this).is(':checked') ) {
      $('#create_list_button').removeAttr('disabled');
      $(".obj-checkbox-selector").prop('checked', true);
    } else {
      $('#create_list_button').attr('disabled', true);
      $(".obj-checkbox-selector").prop('checked', false);
    }
  });

  $('#Segment-Select-lists, #contacts-segment-list').on('change', function(e){
    if (this.value) {
      var window_location = window.location.pathname.split('/');
      window.location = '/' + window_location[1] + '/' + window_location[2]  + '/segments/' + this.value;
    };
  });

  $("#edit-selected-list").click(function(e){
    var selected_edit_list = getSelectedObjectIds();

    if (selected_edit_list.length > 1) {
      return setFlashForList('Only 1 list can be selected for editing', 'error');
    } else if (selected_edit_list.length < 1) {
      return setFlashForList('Please select a list to edit', 'error');
    } else {
      var edit_list_form = $("#edit_list_form").attr("action").split('/');
      edit_list_form.pop();
      console.log(edit_list_form)
      var list_name = $('.obj-checkbox-selector:checked').data("list-name");
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
    // this only applies to creating. edit uses normal http.
    $("form#create_user_list").submit(function(e){
      e.preventDefault();
      $.ajax({
        method: $(this).attr('method'),
        url: $(this).attr('action'),
        data: $(this).serializeArray(),
        dataType: 'json'
      }).done(function(data, msg) {
        setFlashForList('List successfully created', 'notice');
        window.location = data.redirect_url;
      }).fail(function(msg){
        setFlashForList('Unable to complete request', 'error');
      });
    });
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
        $("#segmentChannel").val(getListChannel());
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
        location.reload()
      })
      .fail(function(msg){
        setFlashForList('Unable to create segment', 'error');
      })
  });

  // Fired when the user wants to select checkboxes that fall in a range
  $('.multi-checkbox-select-class').checkboxes('range', true);

  // Fired on click on create list button
  $("#create_list_button").click(function(e) {
    if (!isAnyCheckboxSelected('.obj-checkbox-selector')) {
      setFlashForList('Please select customer from the table', 'error');
    } else {
      obj_ids = getSelectedObjectIds();
      $("#new-list-modal-div").lightbox_me({
        closeClick: true,
        closeEsc: true,
        centered: true,
        onLoad: function() {
          $("#selectedUsers").val(obj_ids);
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

  function isAnyCheckboxSelected(checkbox_class) {
    return $(checkbox_class).is(':checked') || $('#check_or_uncheck_all').is(':checked');
  };

  function setFlashForList(msg, title) {
    FlashHandler.setFlashMessage(msg, title);
  };

  // used by contacts, customers, lists index pages
  function getSelectedObjectIds(){
    var selected_objects = []; // An array for storing selected objects
    $('.obj-checkbox-selector:checked').each(function() {
      selected_objects.push($(this).data('obj-id'));
    });
    return selected_objects;
  };

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
    FlashHandler.setConfirmationDialog("#" + id, 'Are you sure you want to delete this member?', 'Delete', 'destroy-list-members');
  });

  $('.create-segment-modal-btn').click(function() {
    $('#segmentType').val(getListType());
    $("#segmentChannel").val(getListChannel());
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