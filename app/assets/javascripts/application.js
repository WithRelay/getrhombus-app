// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.

// Angular js libraries and dependencies and other js
//
//= require pubnub/pubnub.min.js
//= require jquery
//= require lodash.min
//= require angularjs/angular.min.js
//= require angularjs/angular-route.min.js
//= require angularjs/angular-scrollglue.js
//= require angular-rails-templates

// used for client side form validation
//
//= require formValidation.min
//= require bootstrap-formvalidator.min
//= require url-parameters
//= require moment

// We need to place these js before jquery ujs for workable confirmation dialog box
//= require plan
//= require coupon
//= require subscription

//= require jquery_ujs
//= require angular-smooth-scroll.min
//= require pubnub/pubnub-angular.js
//= require angular-inview
//= require dashboard/messaging_angularjs/messaging.js
//= require dashboard/messaging_angularjs/messagingApp.js.erb
//= require dashboard/messaging_angularjs/messagingControllers.js
//= require dashboard/messaging_angularjs/messagingFilters.js
//= require_tree ./dashboard/messaging_angularjs/templates

// Other js files require tree is included so no need to include all the files in the folder tree
//
//= require pnotify
//= require url-parameters
//= require jquery.lightbox_me
//= require intlTelInput.min
//= require chartist
//= require jquery.payment
//= require cocoon
//= require jquery_word_counter
//= require trumbowyg.min
//= require emojify
//= require emojionearea
//= require trumbowyg_color_plugin
//= require trumbowyg_emoji_plugin
//= require trumbowyg.upload.min
//= require selectize
//= require jquery.checkboxes-1.2.0.min.js
//= require jquery.caret.js
//= require jquery.atwho.js
//= require bootstrap-select
//= require powerange
//= require knowledge_base
//= require flashes
//= require integrations
//= require lists.js
//= require demo
//= require phone_number_formatter
//= require util_functions
//= require price_slider
//= require refer_a_business
//= require get_started
//= require integrations
//= require modernizr
//= require webflow
//= require custom

// DO NOT REQUIRE TREE AS IT DOESNT GUARANTEE THE DEPENDENCY ORDER OF THESE FILES
// require_tree .
