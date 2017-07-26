'use strict';

/* Filters */

angular.module('messagingFilters', [])
  //.filter('filterUserList', function() {  //remove
  .filter('filterConversationList', function() {
    return function(items, query) {
      var filtered = [];
      angular.forEach(items, function(item) {
        if (query == undefined || !query.trim().length || ((item.full_name.toLowerCase().indexOf(query) != -1) || (item.email.toLowerCase().indexOf(query) != -1))) {
          filtered.push(item);
        };
      });
      return filtered;
    };
  })
  .filter('orderObjectBy', function() {
    return function(items, field) {
      var filtered = [];
      angular.forEach(items, function(item) { filtered.push(item); });
      filtered.sort(function (a, b) { return b[field] - a[field]; });
      return filtered;
    };
  });