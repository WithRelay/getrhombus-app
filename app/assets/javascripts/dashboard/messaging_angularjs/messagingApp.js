'use strict';

/* App Module */

var messagingApp = angular.module('PubNubAngularMessagingApp', [
  'ngRoute',
  'templates',
  'messagingControllers',
  'messagingFilters'
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

