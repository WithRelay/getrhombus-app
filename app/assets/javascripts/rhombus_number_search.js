$(document).ready(function () {

	var searchNumBtn = $('#searchNumberBtn');

  var searchNumberCountry = $('#searchNumberCountry'), searchNumberType = $('#searchNumberType'),
    	areaCodeUnavailable = $('#areaCodeUnavailable'), searchNumberField = $('#searchNumberField');

  searchNumBtn.click(function(e) {
		e.preventDefault();
    this.disabled = true;
    this.value = "Searching...";
    get_number(searchNumberField.val(), searchNumberCountry.val(), areaCodeUnavailable.val());
  });
  
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
      	} else
      		FlashHandler.setFlashMessage("We don't have any numbers in this country.", 'error');   
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
});