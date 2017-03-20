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
//= require offline.js

// used for client side form validation
//
//= require formValidation.min
//= require bootstrap-formvalidator.min
//= require url-parameters
//= require moment

// We need to place these js before jquery ujs for workable confirmation dialog box
//= require flashes
//= require get_started
//= require hashtags_plans_coupons_alerts
//= require plan
//= require coupon
//= require subscription
//= require integrations
//= require selectize
//= require angular-selectize

//= require jquery_ujs
//= require pubnub/pubnub-angular.js
//= require angular-inview
//= require_tree ./dashboard/messaging_angularjs/templates
//= require dashboard/messaging_angularjs/messaging.js
//= require dashboard/messaging_angularjs/messagingApp.js.erb
//= require dashboard/messaging_angularjs/messagingControllers.js
//= require dashboard/messaging_angularjs/messagingFilters.js

//= require jquery.lightbox_me
//= require intlTelInput.min
//= require jquery.payment
//= require cocoon
//= require jquery_word_counter
//= require trumbowyg.min
//= require emojify
//= require emojionearea
//= require trumbowyg_color_plugin
//= require trumbowyg_emoji_plugin
//= require trumbowyg.upload.min
//= require jquery.checkboxes-1.2.0.min.js
//= require powerange
//= require knowledge_base
//= require lists.js
//= require images.js.erb
//= require demo
//= require export_csv
//= require sms-usage
//= require phone_number_formatter
//= require clipboard.min
//= require util_functions
//= require stripe.js.erb
//= require credit_card_form
//= require price_slider
//= require refer_a_business
//= require modernizr
//= require webflow
//= require account_setting
//= require jquery.lightbox_me
//= require custom_lightbox
//= require saved_replies
//= require custom_trumbowyg_plugin
//= require campaigns
//= require date_picker
//= require image_validator
//= require campaign_form_validator
//= require reminders
//= require add-user
//= require pagination
//= require list_checkbox_actions
//= require managed-account
//= require custom
//= require rhombus_number_search
//= require typeit
//= require Chart.bundle
//= require chartkick
//= require segment
//= require transactions_refunds
//= require resource_actions

// DO NOT REQUIRE TREE AS IT DOESNT GUARANTEE THE DEPENDENCY ORDER OF THESE FILES
// require_tree .
