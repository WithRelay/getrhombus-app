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

    angular.element('#Messaging-Text-Area').scope().bindEnterToMessagingArea();
  };

  this.get_emoji_box = function() { return msg_emoji_box; };
};

$(document).ready(function () {
  if ($('#Messaging-Text-Area').length) BindConversationPlugins.now();
});
