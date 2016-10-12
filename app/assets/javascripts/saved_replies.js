$(document).ready(function () {

	var action, 
			id = $('.saved-reply-title'),   // hold title for now..will change to the actual id
			form = $('#saved-reply-form');

	
	// set first id
	if (id.length > 0) id = id[0].id.split('-')[3];


	// when a saved reply is click populate form fields and rebuild links
	$(".saved-reply-title").click(function() {
		id = this.id.split('-')[3];
		action = form.attr('action');
		action = action.substring(0, action.lastIndexOf('/') + 1) + id;

		form.attr('action', action);
		$('#delete-saved-reply').attr('href', action)

		set_title_and_text();
	});


	// return saved reply to original state
	$("#saved-reply-cancel").click(function(e) {
		e.preventDefault();
		set_title_and_text();
	});


	// bind emoji to textarea
	$('#saved-reply-body-field').emojioneArea({
		pickerPosition: "bottom",
	});


	function set_title_and_text() {
		$('#saved-reply-title-field').val( $('#saved-reply-title-' + id).text() );
		$('#saved-reply-body-field').val( $('#saved-reply-body-' + id).text() )
	}


});