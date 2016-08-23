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

  def gitlab_issue_link(gitlab_full_name, gitlab_issue_id)
    "#{ Settings.gitlab_base_url }/#{ gitlab_full_name }/issues/#{ gitlab_issue_id }"
  end

  def bitbucket_issue_link(bitbucket_full_name, bitbucket_issue_id)
    "#{ Settings.bitbucket_base_url }/#{ bitbucket_full_name }/issues/#{ bitbucket_issue_id }"
  end

  def feedback_form_name(feedback)
    if feedback.name?
      feedback.name
    else
      user_signed_in? ? current_user.name : feedback.name
    end
  end

  def feedback_form_email(feedback)
    if feedback.email?
      feedback.email
    else
      user_signed_in? ? current_user.email : feedback.email
    end
  end

  def subtask_info_for_report(subtask)
    "#{ "[#{ subtask.task_type }]" if subtask.task_type.present? }" \
      "#{ "[#{ subtask.story_points }] " if subtask.story_points.present? }" \
      "#{ subtask.description }\n"
  end

  def pull_request_info_for_report(pull_request)
    "#{ pull_request.title } " \
      "([##{ pull_request.number_from_provider }](#{ pull_request.url_from_provider }) " \
      "#{ t 'changelogs.changelog.by' } [@#{ pull_request.created_by }](#{ pull_request.author_url }))\n"
  end

  def issue_info_for_report(issue)
    "#{ issue.title } ([##{ issue.send("#{ issue.provider }_issue_number") }]" \
      "(#{ issue.url_from_provider }))\n"
  end

  private

  def authentications_index?
    params[:action].to_s == 'index' && params[:controller].to_s == 'authentications'
  end

  def user_managment_actions?
    params[:action].to_s.in?(%(edit settings)) && params[:controller].to_s == 'users'
  end
end
