module ApplicationHelper
  def edit_navbar_active?
    user_managment_actions? || authentications_index?
  end

  def language_options_for_settings_select
    I18n.available_locales.map { |l| { I18n.t("#{ l }_full") => l } }.reduce(:merge).to_h
  end

  def color_for_column_badge(column)
    return '' if !column.present? || !column.is_a?(Column)

    return 'blue' unless column.max_issues_count.present?

    column.max_issues_count > column.issue_to_section_connections.size ? 'blue' : 'red'
  end

  def issue_tag_color(issue, tag)
    return unless issue.github_labels.present?

    labels = issue.github_labels.select { |label| label[1].last == tag }

    "background-color: ##{ labels[0][2].last };color:black;" if labels[0].present?
  end

  def show_start_sync_button(user, provider)
    return false unless provider.in?(Settings.issues_providers)

    user.send("has_#{ provider }_account") && user.send("sync_with_#{ provider }") != true
  end

  def show_stop_sync_button(user, provider)
    return false unless provider.in?(Settings.issues_providers)

    user.send("has_#{ provider }_account") && user.send("sync_with_#{ provider }") == true
  end

  private

  def authentications_index?
    params[:action].to_s == 'index' && params[:controller].to_s == 'authentications'
  end

  def user_managment_actions?
    params[:action].to_s.in?(%(edit settings)) && params[:controller].to_s == 'users'
  end
end
