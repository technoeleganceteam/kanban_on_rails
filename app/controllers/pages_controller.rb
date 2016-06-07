class PagesController < ApplicationController
  include HighVoltage::StaticPage

  before_action :assign_content_path, :except => [:robots]

  def robots
    render :text => File.read("config/robots.#{ Rails.env }.txt"), :layout => false, :content_type => 'text/plain'
  end

  private

  def assign_content_path
    HighVoltage.content_path = 'pages/'
  end
end
