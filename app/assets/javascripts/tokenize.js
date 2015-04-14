$(document).ready(function () {

    $('#next').click(function() {
        $('.biz_form').toggleClass('show');
    });

    $('#Prev').click(function() {
        $('.biz_form').toggleClass('show');
    });
    
    Stripe.setPublishableKey('pk_test_hQV92i1Ip5Blrrvh7ivixlRY');     //for test
    //Stripe.setPublishableKey('pk_live_REDACTED');     //for production

    // Click event for tokenize credit card
    function preventDefault(e) {
        e.preventDefault();
    }
    
    $("#user-form").bind("submit", preventDefault);
    $('#response').hide();

    $( "#cc-submit" ).click(function() {

        $("#cc-submit").attr("disabled", true);                    
        $('#response').hide();
        $(".panel-body").html('');
        
        Stripe.card.createToken({
            name: $('#cc-name').val(),
            number: $('#cc-number').val(),
            exp_month: $('#cc-ex-month').val(),
            exp_year: $('#cc-ex-year').val(),
            cvc: $('#ex-csc').val()
        }, stripeResponseHandler);
        
        function stripeResponseHandler(status, response) {
            if (response.error) {
                // show the errors on the form
                $('.panel-body').append('=> ' + response.error.message + "<br>");
                $('#response').slideDown(300);
                $("#cc-submit").removeAttr("disabled");
            } else {
                               
                $('#cc-number').val(response["card"]["last4"]);
                $('#cc-uri').val(response['id']);
                $('#cc-type').val(response["card"]["type"]);              
                // unbind prevent default and submit form
                $("#user-form").unbind("submit", preventDefault);
                $("#user-form").submit();
            }
        }
    });
    
    // Simply populates credit card and bank account fields with test data
/*    $('#populate').click(function () {
        $(this).attr("disabled", true);

        $('#cc-name').val('John Doe');
        $('#cc-number').val('<redacted_phone_number>');
        $('#cc-ex-month').val('12');
        $('#cc-ex-year').val('2020');
        $('#ex-csc').val('123');
    });
*/

});