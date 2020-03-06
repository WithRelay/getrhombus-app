$(document).ready(function() {
  function create_rule(formData) {
    $.ajax({
      url: window.location.origin + "/v1/rules",
      method: "POST",
      data: formData,
      dataType: "json"
    })
      .done(function(res) {
        FlashHandler.setFlashMessage(res.notice, "notice");
        location.reload();
      })
      .error(function(res) {
        FlashHandler.setFlashMessage(res.error, "error");
      });
  }

  if ($("#rule-form").length > 0) {
    $("#rule-form")
      .formValidation({
        framework: "bootstrap",
        live: "disabled",
        err: {
          container: function($field, validator) {
            return $field.parent().find(".messageContainer");
          }
        },
        fields: {
          "rule[text]": {
            validators: {
              notEmpty: {
                message: "This field is required"
              }
            }
          },
          "rule[response]": {
            validators: {
              notEmpty: {
                message: "This field is required"
              }
            }
          },
          "rule[message_length]": {
            verbose: false,
            selector: "#message-length",
            validators: {
              notEmpty: {
                message: "Message length is required"
              },
              regexp: {
                regexp: /^\d+$/,
                message: "Invalid Message Length"
              }
            }
          }
        }
      })
      .on("success.form.fv", function(e, data) {
        e.preventDefault();
        create_rule($(this).serialize());
      });
  }

  $("#rule-type").on("change", function() {
    var rule = $(this).val();
    if (
      rule === "contains_text_and_length_is_less_than_x" ||
      rule === "starts_with_text_and_length_is_less_than_x"
    ) {
      $("#message-length-box").show();
    } else {
      $("#message-length-box").hide();
      $("#message-length").val("");
    }
  });

  $(".delete-rule").click(function(evt) {
    var selector = "." + evt.target.classList[evt.target.classList.length - 1];
    if (!$(selector).attr("isDestroy")) {
      evt.stopImmediatePropagation();
      FlashHandler.setConfirmationDialog(
        selector,
        "Are you sure you want to delete rule?",
        "Delete Rule",
        "isDestroy"
      );
      return false;
    }
  });

  $(".handlebar-content-rule").on("click", function() {
    var input = $("#rule-response");
    input.val(input.val() + $(this).attr("data-value"));
  });
});
