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
          
          $scope.$apply(function() {
            if (json_response.user_id == $scope.active_user_id) {
              $scope.selected_user_messages.push({user_id: json_response.user_id, user_level: json_response.user_level, image_url: json_response.image_url, text: json_response.message, ts_day_of_the_week: json_response.ts_day_of_the_week, ts_time: json_response.ts_time, unread: false});
              $scope.users[json_response.user_id].last_message = json_response.message;
              $scope.users[json_response.user_id].last_message_ts = parseInt(json_response.ts_int);
              $http.get('/users/' + merchant_id + '/mark_user_messages_for_merchant_as_read/' + $scope.active_user_id);
            } else {
              if (!$scope.users[json_response.user_id]) {
                $scope.users[json_response.user_id] = {id: json_response.user_id, first_name: json_response.first_name, last_name: json_response.last_name, email: json_response.email, image_url: json_response.image_url, last_message: json_response.message, last_message_ts: json_response.ts_int, unread_count: 0};
                $scope.active_user_count += 1;
              }
              $scope.global_unread_count += 1;
              $scope.users[json_response.user_id].unread_count += 1;
              $scope.users[json_response.user_id].last_message = json_response.message;
              $scope.users[json_response.user_id].last_message_ts = parseInt(json_response.ts_int);
            }
          });
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
            $scope.global_unread_count = (($scope.global_unread_count - $scope.users[user.id].unread_count) > 0) ? $scope.global_unread_count - $scope.users[user.id].unread_count : 0;
            $scope.users[user.id].unread_count = 0;
            $http.get('/users/' + merchant_id + '/mark_user_messages_for_merchant_as_read/' + user.id);
          });
        };
        
        $scope.sendMessage = function(new_message) {
          if ((new_message != undefined) && (new_message.text != '')) {
            $http.get('/users/' + merchant_id + '/send_message_from_merchant/' + $scope.selected_user.id + '?message=' + encodeURI(new_message.text))
            .success(function(data) {
              if (data.success) {
                $scope.selected_user_messages.push({user_id: merchant_id, user_level: data.user_level, image_url: data.image_url, text: new_message.text, ts_day_of_the_week: data.ts_day_of_the_week, ts_time: data.ts_time, unread: false});
                new_message.text = '';
              } else {
                alert('The message could not be sent, please try again.');
              }
            }).
            error(function(data, status, headers, config) {
              alert('The message could not be sent, please try again.');
            });
          }
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

