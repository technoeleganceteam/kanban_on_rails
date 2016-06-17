class PagesController < ApplicationController
  include HighVoltage::StaticPage

  before_action :assign_content_path, :except => [:robots]

  def robots
    render :text => File.read("config/robots.#{ allow_or_disallow_robots }.txt"),
      :layout => false, :content_type => 'text/plain'
  end

  private

  def assign_content_path
    HighVoltage.content_path = 'pages/'
  end

  def allow_or_disallow_robots
    if [Settings.site_url, Settings.websockets.domain,
      Settings.webhook_host, 'https://kanbanonrails.com'].uniq.size == 1
      'allow'
    else
      'disallow'
    end
  end
end
