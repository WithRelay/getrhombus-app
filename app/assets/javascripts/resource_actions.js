$(document).on('ready',function(){
//this function used to delete/deactive Hashtag/Reminder/SavedReply
//It works after the confirmation dialog
	$(document).on('click', '.cancel-yes', function(e){
    e.preventDefault();

    var selectedElement = selectCheckedElement();
		var msg = $(this).parent().find('p').text();

		if (!selectedElement)
			return false

	  if (/deactivate/i.test(msg)){
		  var method_input = selectedElement.parents('.edit_hashtag').find("input[name='_method']");
	    method_input.attr('value','patch');
		}

		doAction(selectedElement);
	});

	$('#edit-saved-reply').on('click',function(){
		var selectedElement = selectCheckedElement();
		var elementForm = selectedElement.closest('form');
		debugger;
		var reply_id = elementForm.find('#saved_reply_id').val();

		$.ajax({
			url:  "/v1/saved_replies/" + reply_id + "/edit" ,
			data:{id: reply_id}
		}).done(function(res){
			debugger;
			var form = $('.editReminderFrom');
		  var action = form.attr("action");
			var newAction = window.location.origin + '/users/' + action.split('/')[2] + '/reminders/' + reminder_id;

			form.find("#Notification-Message").val(res.text);
			form.find(".emojionearea-editor").text(res.text);
			form.attr("action", newAction);

		 	var raw_date_time = res.date_time;
			//  var date_time = new Date(raw_date_time);
			//  var formated_date_time = formatDate(date_time);
			//  form.find("#reminder-date-time").val(formated_date_time);
		}).error(function(){
			 // alert("")
		});

	});

  function selectCheckedElement(){
		var checkedElement = false;
  	$('.table-checkbox').each(function( index, element){
			if ( $(this).is(':checked') )
			 checkedElement =  $(this);
    });
    return checkedElement;
  }

  function doAction(selectedElement){
  	var elementForm = selectedElement.closest('form');

		if (elementForm.length == 0)
			FlashHandler.setFlashMessage('couldnot perform action for the resource','error');
		else
			elementForm.submit();

	  $('.cancel-no').click();
  }
});
