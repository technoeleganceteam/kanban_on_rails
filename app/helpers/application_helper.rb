# Provide view helpers for application
module ApplicationHelper
  def edit_navbar_active?
    user_managment_actions? || authentications_index?
  end

  def feedback_form_name(feedback)
    name = feedback.name

    if name.present?
      name
    else
      user_signed_in? ? current_user.name : name
    end
  end

  def feedback_form_email(feedback)
    email = feedback.email

    if email.present?
      email
    else
      user_signed_in? ? current_user.email : email
    end
  end

  %w(start stop).each do |state|
    define_method "show_#{ state }_sync_button" do |user, provider|
      return false unless provider.in?(Settings.issues_providers)

      user.send("has_#{ provider }_account") &&
        user.send("sync_with_#{ provider }").try(state == 'start' ? :!= : :==, true)
    end
  end

  private

  def authentications_index?
    params[:action].to_s == 'index' && params[:controller].to_s == 'authentications'
  end

  def user_managment_actions?
    params[:action].to_s.in?(%(edit settings)) && params[:controller].to_s == 'users'
  end
end
