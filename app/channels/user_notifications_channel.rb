class UserNotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "user_notifications_#{ current_user.id }"
  end

  def receive(params)
  end

  def unsubscribed
  end
end
