# Service for fetch some stuff from Github
class FetchFromGithub
  include FetchFromSetupable

  def initialize(params = {})
    setup(params)
  end

  def pull_requests
    @client.pull_requests(@project.github_full_name, :state => 'closed')
  end

  define_method "#{ name.sub('FromGithub', '').downcase }_last_commit_date" do |tag|
    changelog = @project.changelogs.find_by(GithubUtilities.tag_name_and_last_commit_sha(tag))

    return changelog.last_commit_date if changelog.present?

    @client.commit(@project.github_repository_id, tag[:commit][:sha]).commit.author.date
  end

  def tags
    @client.tags(@project.github_full_name)
  end
end
