%w(server client).each do |part|
  Sidekiq.send("configure_#{ part }") do |config|
    config.redis = {
      :namespace => [Rails.application.engine_name, Rails.env].join('_'),
      :url => Settings.redis.url
    }
  end
end
