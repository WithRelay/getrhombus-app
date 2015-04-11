'use strict';

/* App Module */

var messagingApp = angular.module('PubNubAngularMessagingApp', [
  'ngRoute',
  'templates',
  'pubnub.angular.service',
  'messagingControllers'
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
