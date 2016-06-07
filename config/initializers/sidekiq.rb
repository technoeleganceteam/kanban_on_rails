Sidekiq.configure_server do |config|
  config.redis = { :namespace => [Rails.application.engine_name, Rails.env].join('_') }
end

Sidekiq.configure_client do |config|
  config.redis = { :namespace => [Rails.application.engine_name, Rails.env].join('_') }
end
