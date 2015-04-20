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

