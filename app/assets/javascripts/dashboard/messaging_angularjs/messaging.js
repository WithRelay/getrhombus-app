var BindPlugins = new function() {
  
  this.now = function () {
	  var is_tribute_binded = false;

	  //function a() {
	  var tribute = new Tribute({
	  	trigger: '/',
		  values: [
		    {key: 'Phil Heartman', value: 'pheartman'},
		    {key: 'Gordon Ramsey', value: 'gramsey'}
		  ],
		  // function called on select that returns the content to insert
		  selectTemplate: function (item) { return item.original.value; },
		  // template for displaying item in menu
  		menuItemTemplate: function (item) { return item.string; },
  		
  		// column to search against in the object (accepts function or string)
  		lookup: 'key',

  		// column that contains the content to insert by default
  		fillAttr: 'value',
		})

  	// bind emoji to textarea
		var msg_emoji_box = $('#message_box').emojioneArea({
			pickerPosition: "bottom",
			events: {
		    // bind tribute
		    focus: function (editor, event) {
		    	// hacky not doubt
		      if (!is_tribute_binded) {
		      	is_tribute_binded = true;
		      	var selector = document.querySelectorAll('.emojionearea-editor')[0];
		      	tribute.attach(selector);
		      	selector.addEventListener('tribute-replaced', function (e) {
    					update_actual_text_box();
						});
		      }
		    },
			}
		})

		// paste - when you paste
		// keyup - so counter is more realtime
		// emojibtn.click - as the name implies
		// blur - good measure, last resort, catch all
		msg_emoji_box[0].emojioneArea.on("blur paste keyup emojibtn.click", function(button, event) {
    	update_actual_text_box();
  	});

  	function update_actual_text_box() {
  		$('#aaa').val(msg_emoji_box[0].emojioneArea.getText())
			angular.element(jQuery('#aaa')).triggerHandler('change');
  	}

  }; 
}

