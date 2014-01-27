$(document).ready(function () {
    
    // Add coode to make this run only on signup pages
    if (window.location.search.substring(1) != "")
    {
        document.getElementById('num').value = window.location.search.substring(1).split("=")[1];
    }
    else
    {
        document.getElementById('num').value = ""
    }
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
    //var marketplaceUri = '/v1/marketplaces/TEST-MP6bP0y8O10lBsBfh8oMGhE4';

    var responseTarget = 'http://requestb.in/y6bbyry6';  
    var marketplaceUri = '/v1/marketplaces/TEST-MP6bP0y8O10lBsBfh8oMGhE4';
    
    balanced.init(marketplaceUri);
    
    ////
    // Click event for tokenize credit card
    ////
    $('#cc-submit').click(function (e) {
        e.preventDefault();

        $('#response').hide();

        var payload = {
            name: $('#cc-name').val(),
            card_number: $('#cc-number').val(),
            expiration_month: $('#cc-ex-month').val(),
            expiration_year: $('#cc-ex-year').val(),
            security_code: $('#ex-csc').val()
        };
        
        // Tokenize credit card
        balanced.card.create(payload, function (response) {
            // Successful tokenization
            if(response.status === 201 && response.href) {
                // Send to your backend
                jQuery.post(responseTarget, {
                    uri: response.href
                }, function(r) {
                    // Check your backend response
                    if (r.status === 201) {
                        // Your successful logic here from backend
                    } else {
                        // Your failure logic here from backend
                    }
                });
            } else {
                // Failed to tokenize, your error logic here
            }
            
            // Debuging, just displays the tokenization result in a pretty div
            $('#response .panel-body pre').html(JSON.stringify(response, false, 4));
            $('#response').slideDown(300);
        });
    });
    
    
    ////
    // Click event for tokenize bank account
    ////
    $('#ba-submit').click(function (e) {
        e.preventDefault();

        $('#response').hide();

        var payload = {
            name: $('#ba-name').val(),
            account_number: $('#ba-number').val(),
            routing_number: $('#ba-routing').val()
        };

        // Tokenize bank account
        balanced.bankAccount.create(payload, function (response) {
            // Successful tokenization
            if(response.status === 201 && response.href) {
                // Send to your backend
                jQuery.post(responseTarget, {
                    uri: response.href
                }, function(r) {
                    // Check your backend response
                    if(r.status === 201) {
                        // Your successful logic here from backend
                    } else {
                        // Your failure logic here from backend
                    }
                });
            } else {
                // Failed to tokenize, your error logic here
            }
            
            // Debuging, just displays the tokenization result in a pretty div
            $('#response .panel-body pre').html(JSON.stringify(response, false, 4));
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