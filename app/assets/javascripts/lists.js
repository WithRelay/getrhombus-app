$(document).on('ready page:load', function() {

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
          setFlashMessage('Something went wrong...Unable to find your lists', 'error');
          callback(); 
        },
        success: function(res) { callback(res['lists']); }
      });
    }
  });

  $( "#click-me" ).click(function() {
    alert(lists_selectize[0].selectize.getValue())
  });

  // prefill form with previous lists
  $.each(campaign_lists, function (index, val) {
    lists_selectize[0].selectize.addItem(val['id']);
  });


  $("form#create_segment").submit(function(e){
    e.preventDefault();
    var action = $(this).attr('action');
    var method = $(this).attr('method');
    var data = $(this).serializeArray();    
    console.log("Action: " + action)
    console.log("Method: " + method)
    console.log(data)
    //debugger;

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


  // Submission of the create list form
  $("form#create_user_list").submit(function(e){
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
      $('#list_form_items').html("List created successfully")
      })
     .fail(function(msg){
      console.log("An error occured")
      process_list_error(msg)
     })
   //debugger;
  })

  // Processes any list submission error
  // and displays appropriate error messages to the user
  function process_list_error(msg){
     var error_div = $("#list_form_errors")
     var response = JSON.parse(msg.responseText)
     errors = response['list_error']
     errors = JSON.parse(errors)
     console.log(errors)
     $.each(errors, function(index, value){
     error_div.html(" ").append(value).css('color', 'red')
    })
   }

  // Toggles between checking or unchecking all checkboxes
 $("#check_or_uncheck_all").click(function(e){
      console.log("Select all checkboxes was clicked")
      if(this.checked){
          $("#merchant_customers").checkboxes('check');
      } else{
         $("#merchant_customers").checkboxes('uncheck');
      }
 })

  // This chunk of code handles the lightbox pop up behavior for creating
  // a new list
  var selected_users = [] // An array for storing selected users


  // Fired when the user wants to select checkboxes that fall in a range
  jQuery(function($) {
    $('#merchant_customers').checkboxes('range', true);
  });

  // Fired on click on create list button
  $("#create_list_button").click(function(e){
    $("#list_create_modal").lightbox_me({
      closeClick: true,
      closeEsc: true,
      centered: true,
      onLoad: function() {
        $("#list_create_modal").find('input:first')
        $("#selected_users").val(selected_users)
        $("#list_type").val("list")
      }
      });
     e.preventDefault();
  });

  // On click of the cancel button close out the lightbox
  $(".cancel").click(function(e){
    $("#list_create_modal").hide();
    $("#segment_create_modal").hide();
  });


  // Fired on click of create segment button
    $("#name_segment").click(function(e){
    $("#segment_create_modal").lightbox_me({
      closeClick: true,
      closeEsc: true,
      centered: true,
      onLoad: function() {
        $("#segment_create_modal").find('input:first')
        $("#list_type").val("segment")
        $("#segment_type").val($("#segment_option").val())
        $("#segment_num_days").val($("#num_days").val())
        $("#segment_filter").val($("#range").val())
      }
      });
     e.preventDefault();
  });
  


  // Fired on click of the segment button
  // Still under development


  num_checkboxes_selected = 0;
  $(".customer_checkboxes" ).change(function() {
    var input = $(this);
    var state = (input.prop("checked"))
    if (state == true){
      num_checkboxes_selected +=1;
      selected_users.push(input.val());
      console.log("Input checked is : ", input.val());

    } else{
      num_checkboxes_selected -=1;
      element_index = selected_users.indexOf(input.val())
      selected_users.splice(element_index, 1);
    }

  if (selected_users.length > 0){
    console.log("There is a selected checkbox.", selected_users);
    $("#create_list_button").prop('disabled', false);
  }else{
    console.log("No selected checkboxes");
    $("#create_list_button").prop('disabled', true);
  }
})
});
