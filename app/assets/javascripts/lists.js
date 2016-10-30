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
        error: function() { callback(); },
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

 $("#select_all_checkboxes").click(function(){
      console.log("Select all checkboxes was clicked")
     $(".customer_checkboxes" ).prop('checked', $(this).prop('checked'));
 })

  // This chunk of code handles the lightbox pop up behavior for creating
  // a new list
  var selected_users = [] // An array for storing selected users

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
