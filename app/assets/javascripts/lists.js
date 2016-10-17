$(document).ready(function () {  

  // this is actyally for campaigns not lists but uses lists
  // http://selectize.github.io/selectize.js/
  var campaign_lists = $('#campaign-select-lists').selectize({
    valueField: 'id',
    labelField: 'name',
    searchField: 'name',
    openOnFocus: false,
    maxOptions: 5,
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
      if (query.length < 3) return callback();
      $.ajax({
        url: window.location.protocol + "//" + window.location.host + "/v1/lists.json?query=" + encodeURIComponent(query),
        error: function() { callback(); },
        success: function(res) { callback(res['lists']); }
      });
    }
  });

  $( "#click-me" ).click(function() {
    alert(campaign_lists[0].selectize.getValue())
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
      daaType: 'json'
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
});