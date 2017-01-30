'use strict';

/* App Module */

//////// smooth scroll
//http://jsfiddle.net/alansouzati/6L7tA/
//https://github.com/d-oliveros/ngSmoothScroll

var messagingApp = angular.module('PubNubAngularMessagingApp', [
  'ngRoute',
  'templates',
  'messagingControllers',
  'messagingFilters',
  "angucomplete-alt",
  "ngFileUpload",
  'angular-inview',
  'duScroll',
  //'messageFetcher',
  'luegg.directives' // Auto scroll module
])

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

messagingApp.directive('whenScrolled', ['$timeout', '$document', function($timeout, $document, duScroll) {
  return function(scope, elm, attr) {
    var raw = elm[0];
    elm.bind('scroll', _.throttle(function() {
      if (raw.scrollTop <= 0) {
        var sh = raw.scrollHeight
        scope.$apply(attr.whenScrolled).then(function() {
          $timeout(function() {
            //raw.scrollTop = raw.scrollHeight - sh;
            $document.duScrollTop(50, 3000).then(function() {
              console && console.log('You just scrolled to the top!');
            });
          })
        });
      }
    }, 250));
};}])

messagingApp.directive('onFinishRender', function ($timeout) {
  return {
      restrict: 'A',
      link: function (scope, element, attr) {
        var raw = element[0];
          if (scope.$last === true) {
            $timeout(function() {
              raw.parentElement.parentElement.scrollTop = raw.parentElement.parentElement.scrollHeight; 
            });
          }
      }
  }
});

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







