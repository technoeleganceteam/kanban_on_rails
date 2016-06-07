class SyncGithubWorker
  include Sidekiq::Worker

  def perform(user_id)
    user = User.where(:id => user_id).first

    return unless user.present?

    user.sync_github
  end
end
