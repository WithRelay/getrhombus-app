var PageParameter = new function() {
  
  // http://www.phpied.com/3-ways-to-define-a-javascript-class/
  var page_params = { num: '', amt: '' };
  parse_page_params();

  function parse_page_params() {
    var params = window.location.search.substring(1), param_str; 
    if (params) {
      params = decodeURIComponent(params).split('&');
      for (var i = 0, l = params.length; i < l; i++) {
        param_str = params[i].split('=');
        page_params[param_str[0]] = param_str[1];
      }
    }
  }
  
  this.get_params = function () {
    return page_params;
  };

}