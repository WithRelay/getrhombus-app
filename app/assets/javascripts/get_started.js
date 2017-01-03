$(document).ready(function () {
  var url = window.location,
    global_page_params = PageParameter.get_params();
  // to prefill signup form or handle captured payments
  // signin is included for when user texts payment and is prompted to sign in to complete account
  // can use form presence instead
  if (["/signup", "/signin", "/users/sign_in", '/users', "/profile"].indexOf(url.pathname) != -1) {
      var amt = validate_captured_amt(global_page_params['amt']);
      if (url.pathname == "/signup") {
          document.getElementById('phone').value = global_page_params['num'];
          hide_account_type(global_page_params['referrer']);
      } else if (url.pathname == "/profile" && amt) {
          cc_submit.prop('value', 'Save & Pay ' + (amt/100));   // on profile page show the amt in button
      } else if (url.pathname == '/users') {
          hide_account_type(document.getElementById('referrer').value);
      }

      if (amt) document.getElementById('captured_amt').value = amt;
  }
  // to prefill signup form or handle captured payments

  function hide_account_type(referrer) {
      if (referrer) {
          $('#signupForm .selectpicker').val('0');
          $('#signupForm .accountTypegroup').hide();
          $("#signup_logo").replaceWith("<h2 class='referrer'>" + referrer + "</h2>");
          $("#rhombusPower").removeClass('hide');
      } else {
          $("#rhombusPower").addClass('hide');
      }
  }

  function validate_captured_amt(str) {
    if (str.match(/^\d+$/)) {
      str = parseInt(str);
      if (str < 1500000) return str;
    }
    return false;
  }
})
