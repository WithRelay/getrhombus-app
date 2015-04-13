'use strict';

/* Controllers */

var messagingControllers = angular.module('messagingControllers', [
  'pubnub.angular.service'
]);

messagingControllers.controller('messagingMainCtrl', ['$scope', '$http', 'PubNub',
  function($scope, $http, PubNub) {
    
    // Get logged in merchant id
    $http.get('/json_get_current_user')
    .success(function(data) {
      var merchant_id = data.id;
      
      // Initialize PubNub
      PubNub.init({
        publish_key: data.pubnub_publish_key,
        subscribe_key: data.pubnub_subscribe_key
      });
      
      // Subscribe to merchant channel
      PubNub.ngSubscribe({
        channel: 'messaging_' + merchant_id,
        message: function(m){
          console.log(m);
        }
      });
      
      // Get latest messages for this merchant
      $http.get('/users/' + merchant_id + '/json_get_latest_active_messaging')
      .success(function(data) {
        $scope.users = data.users;
        
        
      }).
      error(function(data, status, headers, config) {
        alert('Error while trying to connect to the messaging system.');
      });
    }).
    error(function(data, status, headers, config) {
      alert('Error while trying to connect to the messaging system.');
    });
  }
]);

