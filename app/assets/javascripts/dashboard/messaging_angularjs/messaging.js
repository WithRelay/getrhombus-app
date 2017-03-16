var BindConversationPlugins = new function() {

  var msg_emoji_box; //is_atwho_binded = false;

  this.now = function () {

    // bind emoji to textarea
    msg_emoji_box = $('#Messaging-Text-Area').emojioneArea({
      pickerPosition: "top",
      /*events: {
        // bind atwho
        focus: function (editor, event) {
          // hacky no doubt
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
      }*/
    });

    // paste - when you paste, emojibtn.click - as the name implies
    msg_emoji_box[0].emojioneArea.on("paste emojibtn.click", function(button, e) { update_actual_text_box(); })
    .on("keydown", function(btn, e) { if (e.keyCode == 13) e.preventDefault(); });
  };

  // update the angular field that is hidden
  function update_actual_text_box() {
    $('#Messaging-Text-Area').val(msg_emoji_box[0].emojioneArea.getText());
    angular.element(jQuery('#Messaging-Text-Area')).triggerHandler('change');
  };

  this.update_textarea = function() { update_actual_text_box(); };
  this.get_emoji_box = function() { return msg_emoji_box; };
};

$(document).ready(function () {

  if ($('#Messaging-Text-Area').length > 0) {
    BindConversationPlugins.now();
    angular.element(jQuery('#Messaging-Text-Area')).scope().bindEnterToMessagingArea();
  };
  
});
