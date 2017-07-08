var UserDetails = new function() {
  var details_obj = null;

  this.set_object = function() {
    details_obj = $('#user-details').data('user-info');    
  };

  this.id = function() {
    return details_obj.id;
  };

  this.object = function() {
    return details_obj;
  };
};

$(document).ready(function() {
  UserDetails.set_object();
});
