$(document).ready(function () {
    ////
    // Initalize balanced.js
    //
    // server: The backend Balanced server to tokenize with
    // revision: The specific revision of the Balanced API to tokenize with
    ////
    
    // For example purposes, create a bin at http://requestb.in/
    // Make sure it doesn't end in ?inspect and set it as responseTarget.
    // e.g. var responseTarget = http://requestb.in/nyqkn8ny
    //var responseTarget = 'http://localhost';
    //var responseTarget = 'http://requestb.in/189z3371';
    var marketplaceUri = '/v1/marketplaces/TEST-MP6bP0y8O10lBsBfh8oMGhE4';
    
    balanced.init(marketplaceUri);    
    ////
    // Click event for tokenize credit card
    ////
    function preventDefault(e) {
        e.preventDefault();
    }
    
    $("#user-form").bind("submit", preventDefault);

    $('#response').hide();

    $( "#cc-submit" ).click(function() {
        //$("#user-form").bind("submit", preventDefault);
            
        $('#response').hide();
        $( ".panel-body" ).html('');

        var payload = {
            name: $('#cc-name').val(),
            card_number: $('#cc-number').val(),
            expiration_month: $('#cc-ex-month').val(),
            expiration_year: $('#cc-ex-year').val(),
            security_code: $('#ex-csc').val(),
            postal_code: $('#cc-zip').val()
        };
        
        // Tokenize credit card
        balanced.card.create(payload, function (response) {
            // Successful tokenization
            if(response.status === 201 && response.data.uri) {
                
                //set form fields with Balanced data
                $('#cc-name').val(response.data.name);
                $('#cc-number').val(response.data.last_four);
                $('#cc-ex-month').val(response.data.expiration_month);
                $('#cc-ex-year').val(response.data.expiration_year);
                $('#cc-zip').val(response.data.postal_code);
                $('#cc-uri').val(response.data.uri);
                $('#cc-type').val(response.data.card_type);

                // unbind prevent default and submit form
                $("#user-form").unbind("submit", preventDefault);
                $("#user-form").submit();
                
            } else {
               // Failed to tokenize, your error logic here
               var errorJSON = JSON.stringify(response, false, 4);
               var obj = jQuery.parseJSON(errorJSON);

                $.each(obj.error, function(key, value){
                   //alert(key);
                  $('.panel-body').append('=> ' + value + "<br>");
                });
               
            }

            $('#response').slideDown(300);
        });
    });
    
    
    ////
    // Click event for tokenize bank account
    ////
    $('#ba-submit').click(function (e) {
        e.preventDefault();

        $('#response').hide();
        $( ".panel-body" ).html('');

        var payload = {
            name: $('#ba-name').val(),
            account_number: $('#ba-number').val(),
            routing_number: $('#ba-routing').val(),
            //type: $('#ba-type').val()
        };

        // Tokenize bank account
        balanced.bankAccount.create(payload, function (response) {
            // Successful tokenization
            if(response.status === 201 && response.data.uri) {
                //set form fields with Balanced data

                $('#ba-name').val(response.data.name);
                $('#ba-number').val(response.data.account_number);
                $('#ba-routing').val(response.data.routing_number);
                $('#ba-type').val(response.data.type);

                $('#ba-uri').val(response.data.uri);                

                // unbind prevent default and submit form
                $("form").unbind("submit", preventDefault);
                $("form").submit();
            } else {
                // Failed to tokenize, your error logic here
               var errorJSON = JSON.stringify(response, false, 4);
               var obj = jQuery.parseJSON(errorJSON);

                $.each(obj.error, function(key, value){
                   //alert(key);
                  $('.panel-body').append('=> ' + value + "<br>");
                });
            }
            $('#response').slideDown(300);
        });
    });
    
    
    ////
    // Simply populates credit card and bank account fields with test data
    ////
    $('#populate').click(function () {
        $(this).attr("disabled", true);

        $('#cc-name').val('John Doe');
        $('#cc-number').val('<redacted_phone_number>');
        $('#cc-ex-month').val('12');
        $('#cc-ex-year').val('2020');
        $('#ex-csc').val('123');
        $('#ba-name').val('John Doe');
        $('#ba-number').val('<redacted_phone_number>');
        $('#ba-routing').val('321174851');
    });










});