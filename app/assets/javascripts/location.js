$(document).ready(function () {  

  var global_page_params = {};
  var url = window.location;
  
  get_url_parameters();
  function get_url_parameters() {
    var params = url.search.substring(1), param_str; 
    if (params) {
      params = params.split('&');
      for (var i = 0, l = params.length; i < l; i++) {
          param_str = params[i].split('=');
          global_page_params[param_str[0]] = param_str[1];
      }
    }
  };

  function get_ip_info(function_to_run) { 
    $.getJSON('https://ipinfo.io/?token=ae79647534348f', function(data) { 
      function_to_run(data);
    }); 
  };
  
  //get_ip_info(save_referrer_uid);
  function save_referrer_uid(data) {
    if (global_page_params['referrer_uid']) {
      var hash = { referrer: { uid: global_page_params["referrer_uid"] } };

      $.each(data, function( key, value) {
        hash.referrer[key] = value;
      });

      $.ajax({
        url: "/homepage_referrer",
        data: hash
      }).done(function() { console.log('done') });
    };
  };
  



});