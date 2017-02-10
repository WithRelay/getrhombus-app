var BindPlugins = new function() {

  var is_atwho_binded = false, msg_emoji_box;

  this.now = function () {

    // bind emoji to textarea
    msg_emoji_box = $('#Messaging-Text-Area').emojioneArea({
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
      $('#Messaging-Text-Area').val(msg_emoji_box[0].emojioneArea.getText());
      angular.element(jQuery('#Messaging-Text-Area')).triggerHandler('change');
    }
  };

  this.get_emoji_box = function() { return msg_emoji_box; };

}

$(document).ready(function () {

  if ($('#Messaging-Text-Area').length > 0) BindPlugins.now();

  $(".refund-slider").click(function(e) {
    var great_granny = $(this).parent().parent().parent();
    var granny_sibling = great_granny.next();

    if(granny_sibling.is('#refundBox')) {
     (granny_sibling.is(':hidden')) ? granny_sibling.show() : granny_sibling.hide();
    } else {
      great_granny.after($('#refundBox').hide().detach());
      $('#refundBox').show();
    };
  });

  var box, text;
  $("#paste-link").click(function(e) {
    box = BindPlugins.get_emoji_box()[0], text = box.emojioneArea.getText();
    text += " " + angular.element(jQuery('#Messaging-Text-Area')).scope().merchant.short_url;
    box.emojioneArea.setText(text);
  });


});
