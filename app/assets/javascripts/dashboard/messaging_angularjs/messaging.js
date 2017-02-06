var BindPlugins = new function() {
  
  var is_atwho_binded = false;

  this.now = function () {

    // bind emoji to textarea
    var msg_emoji_box = $('#Message-Window').emojioneArea({
      pickerPosition: "top",
      events: {
        // bind atwho
        focus: function (editor, event) {
          // hacky not doubt
          if (!is_atwho_binded) {
            is_atwho_binded = true;
            $('.emojionearea-editor').atwho({
              at: "/",
              searchKey: "title",
              displayTpl: "<li>${title}</li>",
              data: window.location.protocol + "//" + window.location.host + "/v1/saved_replies.json",
              insertTpl: '${body}',
            })
            .on("inserted.atwho", function(event, flag, query) {
              // reinsert as plain text. normally it inserts spans in contenteditable 
              msg_emoji_box[0].emojioneArea.setText(msg_emoji_box[0].emojioneArea.getText())
              update_actual_text_box();
            });
          }
        },
      }
    });

    // paste - when you paste, keyup - so counter is more realtime
    // emojibtn.click - as the name implies, blur - good measure, last resort, catch all
    msg_emoji_box[0].emojioneArea.on("blur paste keyup emojibtn.click", function(button, event) {
      update_actual_text_box();
    });

    // update the angular field that is hidden
    function update_actual_text_box() {
      $('#Message-Window').val(msg_emoji_box[0].emojioneArea.getText())
      angular.element(jQuery('#Message-Window')).triggerHandler('change');
    }
  }; 

}

