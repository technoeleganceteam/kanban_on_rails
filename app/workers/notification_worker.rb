class NotificationWorker
  include Sidekiq::Worker

  def perform(issue_id, user_id)
    acting_user = User.find(user_id)

    issue = Issue.find(issue_id)

    issue.project.users.each do |user| 
      ActionCable.server.broadcast "user_notifications_#{ user.id }",
        :type => :notification,
        :body => action_view.render(:partial => 'shared/notification_body', :format => :txt,
          :locals => { :user => acting_user, :issue => issue }).delete("\n"),
        :title => action_view.render(:partial => 'shared/notification_title', :format => :txt,
          :locals => { :user => acting_user, :issue => issue }).delete("\n"),
        :title_with_body_html => action_view.render(:partial => 'shared/notification_title_with_body_html',
          :format => :txt, :locals => { :user => acting_user, :issue => issue }).delete("\n")
    end
  end

  def action_view
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
