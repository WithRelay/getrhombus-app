# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path
Rails.application.config.assets.paths << "#{Rails.root}/app/assets/html"      # added

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
Rails.application.config.assets.precompile += %w( tokenize.js forms.css mainly_static_pages.css 500.html utils.js custom.js plugins.js bootstrap-select.js)       # added
Rails.application.config.assets.precompile += %w( application_dashboard_messaging.css application_dashboard_messaging.js )