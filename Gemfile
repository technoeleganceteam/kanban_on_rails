source 'https://rubygems.org'

gem 'rails', '4.2.6'

gem 'pg'
gem 'devise'
gem 'devise-encryptable'
gem 'omniauth'
gem 'omniauth-oauth2'
gem 'omniauth-github'
gem 'cancancan'
gem 'actioncable', :git => 'https://github.com/rails/actioncable.git', :ref => '265535'
gem 'turbolinks', :git => 'https://github.com/rails/turbolinks.git'
gem 'sidekiq'
gem 'sinatra', :require => false
gem 'sidekiq-failures'
gem 'redis-namespace'
gem 'rambulance'
gem 'high_voltage'
gem 'config'
gem 'kaminari'
gem 'recaptcha', :require => 'recaptcha/rails'
gem 'rails-i18n'
gem 'valid_email'
gem 'rack-attack'
gem 'redis'
gem 'hiredis'
gem 'devise-async'
gem 'actionpack-action_caching'
gem 'passenger'
gem 'http_accept_language'
gem 'octokit'
gem 'cocoon'
gem 'omniauth-bitbucket'
# until fix this issue https://github.com/bitbucket-rest-api/bitbucket/issues/67
gem 'bitbucket_rest_api', :git => 'https://github.com/bitbucket-rest-api/bitbucket.git'
gem 'postmark-rails'

gem 'sass-rails'
gem 'uglifier'
gem 'coffee-rails'
gem 'therubyracer', :platforms => :ruby
gem 'jquery-rails'
gem 'slim-rails'
gem 'sprockets'
gem 'bootstrap-sass'
gem 'font-awesome-sass'
gem 'js-routes'

gem 'sdoc', :group => :doc

source 'https://rails-assets.org' do
  gem 'rails-assets-dragula'
  gem 'rails-assets-select2'
  gem 'rails-assets-voidberg--html5sortable'
  gem 'rails-assets-js-cookie'
  gem 'rails-assets-noty'
end

group :development do
  gem 'quiet_assets'
  gem 'capistrano'
  gem 'capistrano-rails'
  gem 'capistrano-rvm'
  gem 'capistrano-passenger'
  gem 'capistrano-sidekiq'
  gem 'rubocop'
  gem 'fasterer'
  gem 'traceroute'
  gem 'bullet'
  gem 'brakeman', :require => false
  gem 'rails_best_practices'
  gem 'reek'
  gem 'cane' 
end

group :development, :test do
  gem 'foreman'
  gem 'awesome_print'
  gem 'rspec-rails'
  gem 'pry'
  gem 'pry-remote'
  gem 'byebug'
  gem 'spring'
  gem 'faker'
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'capybara-webkit'
end

group :test do
  gem 'webmock'
  gem 'database_cleaner'
  gem 'simplecov', :require => false
  gem 'shoulda-matchers'
  gem 'factory_girl_rails'
  gem 'hashie'
end

group :production do
  gem 'dalli'
end

