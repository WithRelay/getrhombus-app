$(document).ready(function () {

	var REFUND_TXN_LINK, 
      REFUND_BOX = $('#refundFormBox');

  $('#transactions-column').on("click", ".refund_link", function() {
      REFUND_TXN_LINK = this;
      REFUND_BOX.lightbox_me({
          centered: true,
          onLoad: function() { $('#refundForm').find('input:first').focus(); }
      });
  });

  $('#refundButton').click(function(e) {
    e.preventDefault();
    var refund_btn = this,
        txn_num = REFUND_TXN_LINK.getAttribute('data-txn-num');

    refund_btn.disabled = true;
    refund_btn.textContent = "Please wait...";
    
    $.ajax({
      url: "/v1/transactions/" + txn_num + "/refund.json",
      beforeSend: function(xhr) { xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content')) },
      type: "POST",
      data: { type: "card", reason: document.getElementById('refund_reason').value }
    })
      .done(function(data, textStatus, response) {
        document.getElementById(txn_num).setAttribute("data-status", "Refunded");
         FlashHandler.setFlashMessage(data.message, 'notice');
        $(REFUND_TXN_LINK)[0].parentNode.parentNode.innerHTML = "<tr><td>Status: </td><td> Refunded</td></tr>";
      })
      .fail(function(data, textStatus, response) { 
         FlashHandler.setFlashMessage(data.responseJSON.message, 'error');
      })
      .always(function(data, textStatus, response) {
        refund_btn.disabled = false;
        refund_btn.textContent = "Submit";
        REFUND_BOX.trigger('close');
      });
  });



});