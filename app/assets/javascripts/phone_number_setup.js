$(document).ready(function () {

  console.log($('#hosted_sms_select').val())

  var searchNumBtn = $('#searchNumberBtn');

  var searchNumberCountry = $('#searchNumberCountry'), searchNumberType = $('#searchNumberType'),
      areaCodeUnavailable = $('#areaCodeUnavailable'), searchNumberField = $('#searchNumberField');

  searchNumBtn.click(function(e) {
    e.preventDefault();
    this.disabled = true;
    if (hosted_sms_select.value == 'use-existing-landline') {
      if (!PhoneNumberFormatter.isValid()) {
        $('#phone').addClass('red-border');
        this.disabled = false;
      } else {
        this.value = "Checking...";
        var data = { phone_number: PhoneNumberFormatter.getNumber(), country: $('#hosted-number-country').val(),
                   friendly_name: PhoneNumberFormatter.getNationalFormatNumber() };
        hosted_number_order(data);
      };
    } else {
      this.value = "Searching...";
      get_number(searchNumberField.val(), searchNumberCountry.val(), areaCodeUnavailable.val());
    };
  });

  var hosted_number_order = function (ajax_data) {
    $.ajax({
      url: "/v1/numbers/hosted_number_order.json",
      data: ajax_data,
      type: 'GET',
      dataType: "json"
    })
    .done(function(data, textStatus, jqXHR) {
      if (data.res[0]) {
        FlashHandler.setFlashMessage('Your phone number activation is in progress; this may take up to 2 hours to complete. In the meantime, use the temporary number on your dashboard to get started. We\'ll notify you once your landline is activated', 'success');
        // Continue normal workflow because we still need to issue a regular number to the merchant while hosted number is being activated
        searchNumberCountry.val(ajax_data.country).change();
        searchNumberType.val('local');            // only local numbers for now
        searchNumberField.val('');
        // uncomment later
        //setTimeout(function(){ $('#search_number_form').submit(); }, 2000);
      } else {
        FlashHandler.setFlashMessage(get_status(data.res[1]), 'error');
      }
    })
    .fail(function(data, textStatus, errorThrown) {
      FlashHandler.setFlashMessage("Unfortunately, we are unable to activate Relay on your existing phone number.", 'error');
    })
    .always(function(data, textStatus, response) {
      searchNumBtn.val('Submit').prop("disabled", false);
    });
  }

  function get_status (status) {
    if(status.match('of type voip')) {
      return 'Unfortunately, we are unable to activate Relay on your existing phone number as VOIP number activations are currently not supported.'
    } else {
      return 'Unfortunately, we are unable to activate Relay on your existing phone number.'
    };
  };

  var get_number = function(area_code, country, code_unavailable) {
    $.ajax({
      url: window.location.origin + "/v1/numbers/search.json",
      data: { query: searchNumberField.val(), country: searchNumberCountry.val(), type: searchNumberType.val() },
      dataType: "json"
    })
    .done(function(data, textStatus, jqXHR) {
      if (data.error) {
        FlashHandler.setFlashMessage("We are unable to search for any numbers.", 'error');
      } else if (data.number == '') {
        if (['US', 'CA'].indexOf(country) > -1) {
          if (code_unavailable == 'try_again') {
            FlashHandler.setFlashMessage("We don't have any numbers with that area code, try another.", 'error');
          } else {
            searchNumberField.val('');
            $('#search_number_form').submit();
          }
        } else {
          FlashHandler.setFlashMessage("We don't have any numbers in this country.", 'error');
        }
      } else {
        searchNumberField.val(area_code);
        $('#search_number_form').submit();
      }
    })
    .fail(function(data, textStatus, errorThrown) {
      FlashHandler.setFlashMessage("We are unable to search for any numbers.", 'error');
    })
    .always(function(data, textStatus, response) {
      searchNumBtn.val('Submit').prop("disabled", false);
    });
  }

  var country_num_types = {
    US: { types: ["Local" /*,"Toll Free"*/], show: true },
    CA: { types: ["Local"/*,"Toll Free"*/], show: true },
    PR: { types: ["Local"] },
    GB: { types: ["Local"] },
    // else every other country has mobile type
  };

  searchNumberCountry.change(function() {
    var x = country_num_types[this.options[this.selectedIndex].value.toString()], html = '';
    x = (x) ? x : { types: ["mobile"] };

    for (i = 0, len = x.types.length; i < len; i++) {
      html += '<option value="' + x.types[i].toLowerCase().replace(/ /g, '_') + '">' + x.types[i] + '</option>'
    }

    $('#searchOptions').css( 'display', (x.show) ? 'inline' : 'none' );
    searchNumberType.html(html);
  }).change();
  //// for number search

  $('#hosted_sms_select').on('change', function(){
    if (this.value == 'use-existing-landline') {
      $('.virtual-number-div').hide("slow");
      $('.hosted-number-div').show("slow");
    } else {
      $('.virtual-number-div').attr('class', 'virtual-number-div');
      $('.virtual-number-div').show("slow");
      $('.hosted-number-div').hide("slow");
    };
  })


  if ($('#verify-hosted-sms-order').length > 0) {
    $('#verify-hosted-sms-order')
      .formValidation({
        framework: 'bootstrap',
        live: 'disabled',
        // List of fields and their validation rules
        fields: {
          'VerificationCode': {
            validators: {
              notEmpty: {
                message: 'Verification code is required'
              }
            }
          }
        }
      })
      .on('success.validator.fv', function(e, data) {
          data.element // Get the field element
          .removeClass('has-warning')
          .addClass('has-success')
      })
      .on('success.form.fv', function(e, data) {
          $('#submit-verification-code').attr("disabled", true).val("Please wait...");
      });
  }
});