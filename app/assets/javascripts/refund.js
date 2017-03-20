  $(document).ready(function () {

	var txn_num = '', is_conv_page = false, parent_row;
      btn_html = '', is_cus_profile_page = false;
   
  // transactions page checkbox
  $('.transaction-checkbox').click(function() {
    if ($(this).is(':checked')) {
      $("#refund-charge").removeClass('hide');
      
      is_conv_page = false;
      is_cus_profile_page = false;
      
      parent_row = $(this).closest('.transactions-table-row');
      var amount = parent_row.find('.tran-amount').text();
      var last4 = parent_row.find('.tran-last-four').text();
      txn_num = this.dataset.txnNumber;
      
      $('#tran-amount').text(amount);
      $('#last_four').text(last4);      
    } else {
      $("#refund-charge").addClass('hide');
    }
  });

  // customer profile page refund
  $('.customer-profile-refund-btn').click(function() {
      is_conv_page = false;
      is_cus_profile_page = true;

      parent_row = $(this).closest('.customer-profile-trasaction-table');
      var amount = parent_row.find('.tran-amount').text();
      var last4 = this.dataset.txnLast4;
      txn_num = this.dataset.txnNumber;
      
      $('#tran-amount').text(amount);
      $('#last_four').text(last4);      
  });

  // for conversations page
  $("#right-sidebar-bottom").on('click', '.refund-slider', refund_slider_callback);  
  function refund_slider_callback(e) {
    var great_granny = $(this).parent().parent().parent();
    var granny_sibling = great_granny.next();

    txn_num = e.currentTarget.dataset.txnNumber;
    is_conv_page = true;
    is_cus_profile_page = false;

    if (granny_sibling.is('#refundBox')) {
      (granny_sibling.is(':hidden')) ? granny_sibling.show() : granny_sibling.hide();
    } else {
      great_granny.after($('#refundBox').hide().detach());
      $('#refundBox').show();
    };
  };

  $(document).on('click', '#refund-submit', function(e) {
    e.preventDefault();

    if (txn_num.length) {
      var refund_btn = this;

      refund_btn.disabled = true;

      if (is_conv_page || is_cus_profile_page)
        refund_btn.value = "Please wait...";
      else {
        btn_html = refund_btn.innerHTML;
        refund_btn.innerHTML = "Please wait...";
      }      

      $.ajax({
        url: "/v1/transactions/" + txn_num + "/refund.json",
        beforeSend: function(xhr) { 
          xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
        },
        type: "POST",
        data: { type: "card", reason: document.getElementById('Refund-Reason').value },
        dataType: 'json'
      })
      .done(function(data, textStatus, response) {
        reset_view();
        FlashHandler.setFlashMessage(data.response, 'notice');
      })
      .fail(function(jqXHR, textStatus, errorThrow) { 
        FlashHandler.setFlashMessage(jqXHR.responseJSON.response, 'error');
      })
      .always(function(data, textStatus, response) {
        refund_btn.disabled = false;
        $('#refund-customer-div').trigger('close');

        if (is_conv_page || is_cus_profile_page) {
          refund_btn.value = "Refund";  
        } else {
          refund_btn.innerHTML = btn_html;
        }
      });
    } else {
      FlashHandler.setFlashMessage('This transaction has no transaction number.', 'error');
    }
  });

  // clean up angular array in conv page and update views
  function reset_view() {
    if (is_conv_page) {
      var refund_box_parent = $('#refundBox').parent();
      var index = refund_box_parent[0].dataset.index;
      refund_box_parent.slideUp(400, function() {
        $('#hold-refundBox').html($('#refundBox').hide().detach());
        var scope = angular.element(refund_box_parent).scope();
        scope.$apply(function() {
          scope.customer_transactions.splice(index, 1); 
        }); 
      });
    } else if (is_cus_profile_page) {
      parent_row.slideUp(500, function() { parent_row.remove(); });
    } else {
      parent_row.parent().slideUp(500, function() { parent_row.parent().remove(); });
      $('.checkboxes').attr('disabled', false);
    }
  };


});