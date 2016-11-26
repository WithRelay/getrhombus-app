$(document).ready(function () {

	var REFUND_TXN_LINK, REFUND_BOX = $('#refundFormBox');

  $('#transactions-column').on("click", ".refund_link", function() {
      REFUND_TXN_LINK = this;
      REFUND_BOX.lightbox_me({
          centered: true,
          onLoad: function() { $('#refundForm').find('input:first').focus(); }
      });
  });

  $('#refundButton').click(function(e) {
    e.preventDefault();
    this.disabled = true;
    this.textContent = "Please wait...";
    var charge_id = REFUND_TXN_LINK.getAttribute('data-stripe-txn-num');
    $.ajax({
      url: "/v1/transactions/" + charge_id + "/refund.json",
      beforeSend: function(xhr) { xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content')) },
      type: "POST",
      data: { type: "card", reason: document.getElementById('refund_reason').value }
    })
      .done(function(data, textStatus, response) {
        document.getElementById(charge_id).setAttribute("data-status", "Refunded");
        setFlashMessage(data.message, 'notice');
        $(REFUND_TXN_LINK)[0].parentNode.parentNode.innerHTML = "<tr><td>Status: </td><td> Refunded</td></tr>";
      })
      .fail(function(data, textStatus, response) { 
        setFlashMessage(data.responseJSON.message, 'error');
      })
      .always(function(data, textStatus, response) {
        this.disabled = false;
        this.textContent = "Submit";
        REFUND_BOX.trigger('close');
      });
  });



});