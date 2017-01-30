# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path
Rails.application.config.assets.paths << Rails.root.join('app', 'assets', 'fonts')      # added

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

# added
Rails.application.config.assets.precompile += %w( utils.js custom.js modernizr.js plugins.js bootstrap-select.js )

Rails.application.config.assets.precompile += %w( glyphicons-halflings-regular.eot glyphicons-halflings-regular.svg )
Rails.application.config.assets.precompile += %w( glyphicons-halflings-regular.ttf glyphicons-halflings-regular.woff )
Rails.application.config.assets.precompile += %w( glyphicons-halflings-regular.woff2 )

Rails.application.config.assets.precompile += %w( ProximaNovaSoft-Regular.eot ProximaNovaSoft-Regular.woff2 ProximaNovaSoft-Regular.otf)
Rails.application.config.assets.precompile += %w( ProximaNovaSoft-Regular.ttf ProximaNovaSoft-Regular.woff)

Rails.application.config.assets.precompile += %w( normalize.css webflow.css rho.webflow.css )
Rails.application.config.assets.precompile += %w( formValidation.min.js bootstrap-formvalidator.min.js )
Rails.application.config.assets.precompile += %w( application_dashboard_messaging.css application_dashboard_messaging.js )
