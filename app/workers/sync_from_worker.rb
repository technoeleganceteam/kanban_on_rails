# Sync users projects, issues and hooks from provider by given user id and provider name
class SyncFromWorker
  include Sidekiq::Worker

  def perform(id, provider)
    return unless provider.in?(Settings.issues_providers)

    user = User.find_by(:id => id)

    return unless user.present?

    user.send(self.class.name.underscore.sub('worker', provider))
  end
end
