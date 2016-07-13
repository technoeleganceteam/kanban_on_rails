module Viewable
  extend ActiveSupport::Concern

  private

  def view
    ActionView::Base.new(Rails.configuration.paths['app/views']).tap do |av|
      av.class_eval do
        include Rails.application.routes.url_helpers
        include ApplicationHelper
        include Devise::Controllers::Helpers
        include CanCan::ControllerAdditions
      end
    end
  end
end
