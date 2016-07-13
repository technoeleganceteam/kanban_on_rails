class GenerateChangelogWorker
  include Sidekiq::Worker

  def perform(project_id)
    project = Project.where(:id => project_id).first

    return unless project.present?

    if Settings.issues_providers.map { |provider| project.send("is_#{ provider }_repository") }.any?
      GenerateChangelogs.new(:project => project).handle_changelogs
    end
  end
end
