$(document).ready(function () {

	var txn_num, from_conversation_page = false;
      //REFUND_BOX = $('#refundFormBox');

  // for transaction page
  /*
    $('#transactions-column').on("click", ".refund_link", function() {
      REFUND_TXN_LINK = this;
      REFUND_BOX.lightbox_me({
          centered: true,
          onLoad: function() { $('#refundForm').find('input:first').focus(); }
    });
  });
  */

  // for conversations page
  $("#right-sidebar-bottom").on('click', '.refund-slider', refund_slider_callback);
  
  function refund_slider_callback(e) {
    var great_granny = $(this).parent().parent().parent();
    var granny_sibling = great_granny.next();

    txn_num = e.currentTarget.dataset.txnNumber;
    from_conversation_page = true;

    if (granny_sibling.is('#refundBox')) {
      (granny_sibling.is(':hidden')) ? granny_sibling.show() : granny_sibling.hide();
    } else {
      great_granny.after($('#refundBox').hide().detach());
      $('#refundBox').show();
    };
  };


  $(document).on('click', '#refund-submit', function(e) {
    e.preventDefault();
    var refund_btn = this;

    refund_btn.disabled = true;
    refund_btn.value = "Please wait...";

    $.ajax({
      url: "/v1/transactions/" + txn_num + "/refund.json",
      beforeSend: function(xhr) { 
        xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content')) 
      },
      type: "POST",
      data: { type: "card", reason: document.getElementById('Refund-Reason').value }
    })
    .done(function(data, textStatus, response) {
      FlashHandler.setFlashMessage(data.message, 'notice');
      reset_view();      
    })
    .fail(function(data, textStatus, response) { 
       FlashHandler.setFlashMessage(data.responseJSON.message, 'error');
    })
    .always(function(data, textStatus, response) {
      refund_btn.disabled = false;
      refund_btn.value = "Refund";
      //REFUND_BOX.trigger('close');
    });
  });

  function reset_view() {
    if (from_conversation_page) {
      setTimeout(function() { // refresh transaction list
        $('#hold-refundBox').html($('#refundBox').hide().detach());
        angular.element(jQuery('#Messaging-Text-Area')).scope().getCustomerTransactions(); 
      }, 2500);          
    } else {
      // remove div from table
    }
  }


});