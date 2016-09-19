# Application utilities
module ApplicationUtilities
  class << self
    def allow_or_disallow_robots
      if [Settings.site_url, Settings.websockets.domain,
        Settings.webhook_host, 'https://kanbanonrails.com'].uniq.size == 1
        'allow'
      else
        'disallow'
      end
    end

    def language_options_for_settings_select
      I18n.available_locales.map { |locale| { I18n.t("#{ locale }_full") => locale } }.reduce(:merge).to_h
    end
  end
end
