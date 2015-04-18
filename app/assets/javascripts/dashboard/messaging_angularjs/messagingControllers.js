'use strict';

/* Controllers */

var messagingControllers = angular.module('messagingControllers', [
  'pubnub.angular.service'
]);

messagingControllers.controller('messagingMainCtrl', ['$scope', '$http', 'PubNub',
  function($scope, $http, PubNub) {
    $scope.active_user_id = 0;
    $scope.active_user_count = 0;
    $scope.global_unread_count = 0;
    
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
          var json_response = JSON.parse(m[0]);
          
          if (json_response.user_id == $scope.active_user_id) {
            $scope.$apply(function() {
              $scope.selected_user_messages.push(json_response);
              $scope.users[json_response.user_id].last_message = json_response.text;
              $http.get('/users/' + merchant_id + '/mark_user_messages_for_merchant_as_read/' + $scope.active_user_id);
            });
          } else {
            $scope.$apply(function() {
              $scope.global_unread_count += 1;
              $scope.users[json_response.user_id].unread_count += 1;
              $scope.users[json_response.user_id].last_message = json_response.text;
            });
          }
        }
      });
      
      // Get latest messages for this merchant
      $http.get('/users/' + merchant_id + '/json_get_latest_active_messaging')
      .success(function(data) {
        
        var user_list = {};
        // Build user list and count initial global unread
        angular.forEach(data.users, function(value, key) {
          user_list[value.id] = value;
          $scope.active_user_count += 1;
          $scope.global_unread_count += value.unread_count;
        });
        
        $scope.users = user_list;
        
        $scope.getUserMessages = function(user) {
          $http.get('/users/' + merchant_id + '/json_get_user_messages_by_merchant/' + user.id + '?limit=' + (user.unread_count + 3))
          .success(function(data) {
            $scope.active_user_id = user.id;
            $scope.selected_user = user;
            $scope.selected_user_messages = data.messages;
            
            // Mark messages as read
            $scope.global_unread_count -= $scope.users[user.id].unread_count;
            $scope.users[user.id].unread_count = 0;
            $http.get('/users/' + merchant_id + '/mark_user_messages_for_merchant_as_read/' + user.id);
          });
        };
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

