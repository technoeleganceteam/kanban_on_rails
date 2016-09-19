# Generate changlog for specified project
class GenerateChangelogsWorker
  include Sidekiq::Worker

  def perform(project_id)
    project = Project.where(:id => project_id).first

    return unless project.present?

    return unless project.provider.present?

    self.class.name.sub('Worker', '').constantize.new(:project => project).generate
  end
end
