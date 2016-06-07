require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module KanbanOnRails
  class Application < Rails::Application
    config.middleware.use Rack::Attack

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.i18n.available_locales = %w(af ar az be bg bn bs ca cs cy da de el en eo es et eu fa
      fi fr gl he hi hr hu id is it ja km kn ko lb lo lt lv mk ml mn mr-IN ms nb ne nl nn or pa
      pl pt rm ro ru sk sl sr sv sw ta th tl tr tt ug uk ur uz vi wo zh-CN zh-TW)

    I18n.enforce_available_locales = false

    config.i18n.fallbacks = [:en, :ru]

    config.active_record.raise_in_transactional_callbacks = true

    config.middleware.delete 'Rack::Lock'

    config.active_job.queue_adapter = :sidekiq
  end
end
