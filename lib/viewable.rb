# Provide view helper for models and over classes.
# Usefull when creating notifications for example.
module Viewable
  extend ActiveSupport::Concern

  private

  def view
    ActionView::Base.new(Rails.configuration.paths['app/views']).tap do |action_view|
      add_helpers(action_view)
    end
  end

  def add_helpers(action_view)
    action_view.class_eval do
      include Rails.application.routes.url_helpers
      include ApplicationHelper
      include Devise::Controllers::Helpers
      include CanCan::ControllerAdditions
    end
  end
end
