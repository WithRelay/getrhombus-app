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

	if ($('.save-reply-form').length) {
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
	}


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

	// Confirmation dialog box for destroy saved reply
	$('#delete-saved-reply').click(function(evt) {
		var selectedElement = selectCheckedElement();
		if(selectedElement == false){
			FlashHandler.setFlashMessage('Please select a reply first','error');
			return false;
		}
		else if (!$('#delete-saved-reply').attr('isDestroy')) {
			FlashHandler.setConfirmationDialog('#delete-saved-reply','Confirmation Needed', 'Are you sure?', 'isDestroy' )
			return false;
		}
	});

$('#delete-reminder').click(function(e){
	var selectedElement = selectCheckedElement();
	if(selectedElement == false){
		FlashHandler.setFlashMessage('Please selcect a reminder first','error');
		return false;
	}
	else {
	      e.preventDefault
	      FlashHandler.setConfirmationDialog('#delete-reminder','Are you sure, you want to delete the Reminder?', 'Delete', 'isDistroy');
	      return false;
			}
	});

	$('#edit-saved-reply').on('click',function(e){

		var selectedElement = selectCheckedElement();
		if (selectedElement == false){
			FlashHandler.setFlashMessage('record not selected','error');
			return false;
		}
		else{
			$("#edit-saved-reply-modal").lightbox_me({
				centered: true
			});
		}

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


	$('#edit-reminder').on('click', function(){
		var selectedElement = selectCheckedElement();

		if (selectedElement == false){
			FlashHandler.setFlashMessage('record not selected','error');
			return false;
		}else{
			$("#edit-reminder-modal").lightbox_me({
				centered: true
			});

		}
		var elementForm = selectedElement.closest('form');
		var reminder_id = elementForm.find("#reminder_id").val();

		 $.ajax({
			 url:  "/v1/reminders/" + reminder_id + "/edit" ,
			 data:{id: reminder_id}
		 }).done(function(res){
			debugger;
			var form = $('.editReminderFrom');
			var action = form.attr("action");
			var reminder = res.reminder
			var reminder_lists = res.reminder_lists;
			var newAction = window.location.origin + '/users/' + action.split('/')[2] + '/reminders/' + reminder_id;
			customtersSearch(reminder_lists);
			var selectField = $('.editReminderFrom .search-customers-and-contacts')[0].selectize;
			selectField.addItem(reminder_lists[0].id, false);
			form.find("#Notification-Message").val(reminder.text);
			form.find(".emojionearea-editor").text(reminder.text);
			form.attr("action", newAction);

			var raw_date_time = reminder.date_time;
			var date_time = new Date(raw_date_time);
			var formated_date_time = formatDate(date_time);
			form.find("#reminder-date-time").val(formated_date_time);
		 }).error(function(){
				// alert("")
		 })
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

	$('#set-new-reminder-loader').click(function(){
    customtersSearch();
  });

function customtersSearch(option = []){
  var labelSearchField = option.length < 1 ? 'description' : 'phone_number'
  var valueField = option.length < 1 ? 'uid' : 'id'
  $('.search-customers-and-contacts').selectize({
    maxItems: 1,
    valueField: valueField,
    labelField: labelSearchField,
    searchField: labelSearchField,
    create: false,
    options: option,
    closeAfterSelect: true,
    load: function(query, callback) {
      if (!query.length) return callback();
      $.ajax({
        url: '/v1/users.json',
        type: 'GET',
        dataType: 'json',
        data: {
          query: query
        },
        error: function() {
          FlashHandler.setFlashMessage('Something went wrong...Unable to find any customer', 'error');
          callback();
        },
        success: function(res) {
          callback(res['data']);
        }
      });
    }
  });
}

});
