$(document).ready(function () {  

  //get_ip_info(save_referrer_uid);
  
  function get_ip_info(function_to_run) { 
    $.getJSON(UtilFunctions.get_ipinfo_url(), function(data) { 
      function_to_run(data);
    });
  };
  
  function save_referrer_uid(data) {
    var params = PageParameter.get_params();
    if (params['referrer_uid']) {
      var hash = { referrer: { referrer_uid: params["referrer_uid"] } };

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