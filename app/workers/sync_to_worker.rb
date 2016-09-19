# Sync issue to provider by gived issue id, user id and provider name
class SyncToWorker
  include Sidekiq::Worker

  def perform(id, user_id, provider)
    return unless provider.in?(Settings.issues_providers)

    issue = Issue.find_by(:id => id)

    return unless issue.present?

    issue.send(self.class.name.underscore.sub('worker', provider), user_id)
  end
end
