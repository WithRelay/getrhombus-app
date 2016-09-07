$(document).ready(function () {  

  var global_page_params = {};
  var url = window.location;
  function GetURLParameter() {
    var params = url.search.substring(1), param_str; 
    if (params) {
      params = params.split('&');
      for (var i = 0, l = params.length; i < l; i++) {
          param_str = params[i].split('=');
          global_page_params[param_str[0]] = param_str[1];
      }
    }
  }

  GetURLParameter();
  if (global_page_params['referrer_uid']) {
    $.getJSON('https://ipinfo.io/?token=ae79647534348f ', function(data){
      var hash = { referrer: { uid: global_page_params["referrer_uid"] } };
      $.each(data, function( key, value) {
        hash.referrer[key] = value;
      });

      $.ajax({
        url: "/homepage_referrer",
        data: hash
      }).done(function() { console.log('done') });
      console.log(hash) 
    }); 

  }  



});