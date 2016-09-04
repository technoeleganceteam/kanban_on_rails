class SyncGitlabWorker
  include Sidekiq::Worker

  def perform(user_id)
    user = User.where(:id => user_id).first

    return unless user.present?

    user.send(self.class.name.underscore.sub('_worker', ''))
  end
end
