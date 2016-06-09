class SyncGitlabIssueWorker
  include Sidekiq::Worker

  def perform(issue_id, user_id)
    issue = Issue.where(:id => issue_id).first

    return unless issue.present?

    issue.sync_with_gitlab(user_id)
  end
end
