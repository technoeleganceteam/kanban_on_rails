class NotificationWorker
  include Sidekiq::Worker

  def perform(issue_id, user_id)
    @user = User.find(user_id)

    @issue = Issue.find(issue_id)

    @issue.project.users.each do |user|
      ActionCable.server.broadcast "user_notifications_#{ user.id }", :type => :notification,
        :body => render_body, :title => render_title, :title_with_body_html => render_title_with_body_html
    end
  end

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

  %w(body title title_with_body_html).each do |part|
    define_method "render_#{ part }" do
      view.render({ :partial => "shared/notification_#{ part }" }.merge(params)).delete("\n")
    end
  end

  def params
    { :format => :txt, :locals => { :user => @user, :issue => @issue } }
  end
end
