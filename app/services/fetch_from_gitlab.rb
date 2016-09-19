# Service for fetch some stuff from Gitlab
class FetchFromGitlab
  include FetchFromSetupable

  def initialize(params = {})
    setup(params)
  end

  def tags
    @client.tags(@project.gitlab_repository_id)
  end

  def pull_requests
    @client.merge_requests(@project.gitlab_repository_id, :state => 'merged')
  end

  define_method "#{ name.sub('FromGitlab', '').downcase }_last_commit_date" do |tag|
    DateTime.parse(tag.commit.committed_date).utc
  end
end
