$(document).ready(function() {
  // All reviewed
  // used by campaign index

  $(".delete-resource").click(function(e) {
    var statusName = campaignStatusName();

    if (!statusName) {
      showUncheckError();
    } else if (statusName != "inactive") {
      FlashHandler.setConfirmationDialog(
        ".delete-resource",
        "Are you sure you want to delete this campaign?",
        "Delete"
      );
    } else if (statusName) {
      FlashHandler.setFlashMessage(
        "An inactive campaign cannot be deleted",
        "error"
      );
    }
  });

  // used by campaign index
  $(".deactivate-resource").click(function(e) {
    var statusName = campaignStatusName();
    var text = { paused: "Activate", active: "Pause", inactive: "Activate" };

    if (!statusName) {
      showUncheckError();
    } else {
      //if (statusName != "inactive") {
      FlashHandler.setConfirmationDialog(
        ".deactivate-resource",
        "Are you sure you want to " +
          text[statusName].toLowerCase() +
          " this campaign?",
        text[statusName]
      );
    } /*else if (statusName) {
      FlashHandler.setFlashMessage('You need to edit an inactive campaign settings to activate it', 'error' );
    };*/
  });

  function showUncheckError() {
    FlashHandler.setFlashMessage("Please select a campaign", "error");
  }

  function campaignStatusName() {
    return $(".checkboxes:checked")
      .parent()
      .find(".resource-status")
      .text();
  }

  // used by campaign index
  $("#objlists").on("click", ".get-campaign-data", function(e) {
    e.preventDefault();
    var $this = $(this);

    if ($this.hasClass("clicked")) return false;
    else {
      $this.addClass("clicked");
      $.ajax({
        url: "/v1/campaigns/" + $this.attr("data-campaign-id") + "/data",
        dataType: "json",
        error: function() {
          FlashHandler.setFlashMessage("Unable to submit request", "error");
        },
        success: function(res) {
          FlashHandler.setFlashMessage("Request submitted", "notice");
        },
        complete: function() {
          $this.removeClass("clicked");
        }
      });
    }
  });
});
