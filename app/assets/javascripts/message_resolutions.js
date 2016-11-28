$(document).ready(function() {

  var action,
    id = $('.message-resolution-title'), // hold title for now..will change to the actual id
    form = $('#message-resolution-form');


  // set first id
  if (id.length > 0) id = id[0].id.split('-')[3];


  // when a message resolution is click populate form fields and rebuild links
  $('.message-resolution-title').click(function() {
    id = this.id.split('-')[3];
    action = form.attr('action');
    action = action.substring(0, action.lastIndexOf('/') + 1) + id;

    form.attr('action', action);
    $('#delete-message-resolution').attr({
      href: action,
      disabled: (this.getAttribute("data-has-conversation") == "true") ? true : false
    });

    set_title();
  });


  // return message resolution to original state
  $('#message-resolution-cancel').click(function(e) {
    e.preventDefault();
    set_title();
  });

  function set_title() {
    $('#message-resolution-title-field').val($('#message-resolution-title-' + id).text().trim());
  }

  // Confirmation dialog box for destroy message resolution
  $('#delete-message-resolution').click(function(evt) {
    if (!$('#delete-message-resolution').attr('isDestroy')) {
      FlashHandler.setConfirmationDialog('#delete-message-resolution','Confirmation Needed', 'Are you sure?', 'isDestroy' )
      return false;
    }
  });
});
