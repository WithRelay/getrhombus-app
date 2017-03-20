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


	$('.save-reply-form').formValidation({
		framework: 'bootstrap',
		excluded: ':disabled',
		live: 'disabled',
		err: {
					container: function($field, validator) {
							return $field.parent().find('.messageContainer');
					}
			},
		fields: {
			'saved_reply[title]': {
				validators: {
					notEmpty: {
						message: 'This Field is required'
					}
				}
			},
			'saved_reply[body]':{
				validators: {
					notEmpty: {
						message: 'This Field is required'
						}
					}
				}
			}
	}).on('success.form.fv', function(e, data) {
			if (this.id != 'edit-save-reply-form'){
				e.preventDefault();
				create_saved_reply($(this).serialize());
			}

			$('.update-close-modals').click();
		});


	function create_saved_reply(formData){
		$.ajax({
			url: window.location.origin + "/v1/saved_replies",
			method: "POST",
			data: formData,
			dataType: 'json'
		}).done(function(res){
			FlashHandler.setFlashMessage(res.notice,'notice');
			}).error(function(res){
				FlashHandler.setFlashMessage(res.error, 'error');
		});
	}

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

			 form.find("#Edit-Saved-Reply-Title").val(res.title);
			 form.find(".emojionearea-editor").text(res.body);
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
