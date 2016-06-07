module ApplicationHelper
  def edit_navbar_active?
    params[:action].to_s.in?(%(edit settings)) && params[:controller].to_s == 'users' ||
      (params[:action].to_s == 'index' && params[:controller].to_s == 'authentications')
  end

  def language_options_for_settings_select
    I18n.available_locales.map { |l| { I18n.t("#{ l }_full") => l } }.reduce(:merge).to_h
  end

  def color_for_column_badge(column)
    return '' if !column.present? || !column.is_a?(Column)

    return 'blue' unless column.max_issues_count.present?

    column.max_issues_count > column.issue_to_section_connections.size ? 'blue' : 'red'
  end
end
