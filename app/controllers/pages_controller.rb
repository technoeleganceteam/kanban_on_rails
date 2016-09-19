# Controller for handle static pages
class PagesController < ApplicationController
  include HighVoltage::StaticPage
  include ContentPathable

  def robots
    render :text => File.read("config/robots.#{ ApplicationUtilities.allow_or_disallow_robots }.txt"),
      :layout => false, :content_type => 'text/plain'
  end
end
