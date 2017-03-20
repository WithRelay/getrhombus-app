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
		var reply_id = elementForm.find('#saved_reply_id').val();

		$.ajax({
			url:  "/v1/saved_replies/" + reply_id + "/edit" ,
			data:{id: reply_id}
		}).done(function(res){
			 var form = $('#edit-save-reply-form');
			 var action = form.attr("action");
			 var newAction = window.location.origin + '/users/' + action.split('/')[2] + '/saved_replies/' + reply_id;

			 form.find("#Edit-Saved-Replies-Editor").val(res.body);
			 form.find("#Edit-Saved-Reply-Title").val(res.title);
			 form.attr('action',newAction);

			}).error(function(){
				FlashHandler.setFlashMessage('Request cannot perform','error');
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
