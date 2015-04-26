'use strict';

/* App Module */

var messagingApp = angular.module('PubNubAngularMessagingApp', [
  'ngRoute',
  'templates',
  'messagingControllers',
  'messagingFilters',
  'luegg.directives' // Auto scroll module
]);

messagingApp.config(['$routeProvider',
  function($routeProvider) {
    $routeProvider.when('/', {
      templateUrl : 'dashboard/messaging_angularjs/templates/index.html',
      controller : 'messagingMainCtrl'
    }).otherwise({
      redirectTo : '/'
    });
  }
]);

/* Directive to detect enter key presses */
messagingApp.directive('ngEnter', function() {
  return function(scope, element, attrs) {
    element.bind("keydown keypress", function(event) {
      if (event.which === 13) {
        scope.$apply(function() {
          scope.$eval(attrs.ngEnter);
        });

        event.preventDefault();
      }
    });
  };
}); 
