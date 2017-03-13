$(document).on('ready page:load', function() {


  $("form#create_segment").submit(function(e){
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
      console.log("Segment created successfully")
      $('#segment_create_msg').html("Segment created successfully")
    })
    .fail(function(msg){
      console.log("Segment could not be created")
      $('#segment_create_msg').html("Segment could not be created")
    })
  })

  $("#delete-lists").click(function(){
    FlashHandler.setConfirmationDialog('#delete-lists','Are you sure, you want to delete selected lists?', 'Delete', 'destroy-lists');
  });

  $("#send-campaign-to-lists").click(function(){
    var selected_item = getSelectedUserIds();
    var link = $(this).data('lists-campaign');
    var link_with_list_ids = link + '?list_id=' + selected_item;
    window.location = link_with_list_ids;
  });

  $(document).on('click', '.cancel-yes', function(e){
    var delete_link = $('#delete-lists').data('delete-list-link');
    var selected_item = getSelectedUserIds();
    $.post(delete_link, { list_id: selected_item });
  });

  // Toggles between checking or unchecking all checkboxes
  $("#check_or_uncheck_all").click(function(e){
    if( $(this).is(':checked') ){
      $('#create_list_button').removeAttr('disabled');
      $(".merchant_customers").prop('checked', true);
    }else{
      $(".merchant_customers").prop('checked', false);
    }
  });

  $('.merchant_customers').click(function(){
    $(this).is(':checked') && $('#create_list_button').removeAttr('disabled')
  });

  $('#create_user_list').formValidation({
    framework: 'bootstrap',
    live: 'disabled',
    err: {
      container: function($field, validator) {
        return $field.parent().find('.messageContainer');
      }
    },
    fields: {
      'lists[list_name]': {
        excluded: false,
        verbose: false,
        validators: {
          notEmpty: {
            message: 'Campaign name is required'
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
          setFlashForList('List successfully Created', 'notice');
          $('.close-modal').click();
        }
      }).fail(function(msg){
        setFlashForList(msg, 'error');
      });
    })
  });

  // Fired when the user wants to select checkboxes that fall in a range
  jQuery(function($) {
    $('#merchant_customers').checkboxes('range', true);
  });

  // Fired on click on create list button
  $("#create_list_button").click(function(e){
    if (!isAnyCheckboxSelected('.merchant_customers')){
      setFlashForList('Please select customer from the table', 'error');
    }
    else{
      user_ids = getSelectedUserIds();
      $("#import-customers-div").lightbox_me({
        closeClick: true,
        closeEsc: true,
        centered: true,
        onLoad: function() {
          $("#selectedUsers").val(user_ids);
          $("#listType").val("list");
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
  }


  // Fired on click of create segment button
  $("#name_segment").click(function(e){
    $("#segment_create_modal").lightbox_me({
      closeClick: true,
      closeEsc: true,
      centered: true,
      onLoad: function() {
        // Populate segment selection before submitting request
        $("#segment_create_modal").find('input:first')
        $("#list_type").val("segment")
        $("#segment_type").val($("#segment_option").val())
        $("#segment_num_days").val($("#num_days").val())
        $("#segment_filter").val($("#range").val())
        $("#amt_filter").val($("#amount_filter").val())
        $("#amt_1").val($("#amount_1").val())
        $("#amt_2").val($("#amount_2").val())
      }
    });
    e.preventDefault();
  });


  function getSelectedUserIds(){
    var selected_users = []; // An array for storing selected users
    $('.merchant_customers:checked').each(function(){
      selected_users.push($(this).data('users'));
    })
    return selected_users.join(',');
  }
  // Fired on click of the segment button
  // Still under development


  //   num_checkboxes_selected = 0;
  //   $(".customer_checkboxes" ).change(function() {
  //
  //     var input = $(this);
  //     var state = (input.prop("checked"))
  //     if (state == true){
  //       num_checkboxes_selected +=1;
  //       selected_users.push(input.val());
  //       console.log("Input checked is : ", input.val());
  //
  //     } else{
  //       num_checkboxes_selected -=1;
  //       element_index = selected_users.indexOf(input.val())
  //       selected_users.splice(element_index, 1);
  //     }
  //   if (selected_users.length > 0){
  //     console.log("There is a selected checkbox.", selected_users);
  //     $("#create_list_button").prop('disabled', false);
  //   }else{
  //     console.log("No selected checkboxes");
  //     $("#create_list_button").prop('disabled', true);
  //   }
  // })
});
