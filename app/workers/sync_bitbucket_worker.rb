class SyncBitbucketWorker
  include Sidekiq::Worker

  def perform(user_id)
    user = User.where(:id => user_id).first

    return unless user.present?

    user.sync_bitbucket
  end
end
