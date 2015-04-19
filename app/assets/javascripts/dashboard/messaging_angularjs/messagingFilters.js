'use strict';

/* Filters */

angular.module('messagingFilters', []).filter('filterUserList', function() {
  return function(items, query) {
    var filtered = [];
    angular.forEach(items, function(item) {
      if ((query == undefined) || ((item.first_name.toLowerCase().indexOf(query) != -1) || (item.last_name.toLowerCase().indexOf(query) != -1) || (item.email.toLowerCase().indexOf(query) != -1))) {
        filtered.push(item);
      }
    });
    return filtered;
  };
}).filter('orderObjectBy', function() {
  return function(items, field, reverse) {
    var filtered = [];
    angular.forEach(items, function(item) {
      filtered.push(item);
    });
    filtered.sort(function (a, b) {
      return (a[field] > b[field] ? 1 : -1);
    });
    if(reverse) filtered.reverse();
    return filtered;
  };
});
