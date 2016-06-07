# Be sure to restart your server when you modify this file.

Rails.application.config.session_store :cookie_store, :key => '_kanban_on_rails_session',
  :expire_after => 2.weeks, :secure => %w(production staging).include?(Rails.env)
