$(document).ready(function () {

	var searchNumBtn = $('#searchNumberBtn');

  $('#search_number_form').formValidation({
    framework: 'bootstrap',
    live: 'disabled',
    fields: {
      'demo[full_name]': {
        validators: {
          notEmpty: {
            message: 'Required'
          }
        }
      }
    }
  })
  .on('success.form.fv', function(e, data) {
    e.preventDefault();
    
    $('#commit_demo').attr("disabled", true).val("Please wait...");
  });
  ////

  //// for number search - move to separate file
  searchNumBtn.click(function() {
      this.disabled = true;
      this.innerHTML = "Searching...";
      get_number();
  });

  var searchNumberCountry = $('#searchNumberCountry'),
    	searchNumberType = $('#searchNumberType'),
    	searchNumberField = $('#searchNumberField');
  
  var get_number = function(str) {
    $.ajax({
      url: "/v1/numbers/search.json",
      type: "GET",
      data: { query: searchNumberField.val(), country: searchNumberCountry.val(), type: searchNumberType.val() },
      dataType: "json"
    })
    .done(function(data, textStatus, jqXHR) {
      var str = '';
      if(data.error) {
        alert('something went wrong');
      } else if (data.number == '') {
        alert(':( we dont have any number');
      } else {
        alert(data.number);
      }
    })
    .fail(function(data, textStatus, errorThrown) {
      alert('something went wrong');
      console.log(data);
    })
    .always(function(data, textStatus, response) {
      searchNumBtn.html('Search').prop("disabled", false);
    });
  }

  var country_num_types = {
    US: { types: ["Local","Toll Free"], show: true },
    CA: { types: ["Local","Toll Free"], show: true },
    PR: { types: ["Local"] },
    GB: { types: ["Local"] },
    // else mobile and don't show
  };

  searchNumberCountry.change(function() {
    var x = country_num_types[this.options[this.selectedIndex].value.toString()];
    		//, html = '';
    x = (x) ? x : { types: ["mobile"] };
    /*for (i = 0, len = x.types.length; i < len; i++) {
      html += '<option value="' + x.types[i].toLowerCase().replace(/ /g, '_') + '">' + x.types[i] + '</option>'
    }*/
    var display = (x.show) ? 'inline' : 'none';
    //searchNumberType.html(html).css('display', display);
    searchNumberField.val('').css('display', display)
  });
  //// for number search
});