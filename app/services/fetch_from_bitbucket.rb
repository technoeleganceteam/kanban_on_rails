# Service for fetch some stuff from Bitbucket
class FetchFromBitbucket
  include FetchFromSetupable

  def initialize(params = {})
    setup(params)
  end

  def tags
    @client.repos.tags(@project.bitbucket_owner, @project.bitbucket_slug)
  end

  def pull_requests
    @client.repos.pull_request.
      list(@project.bitbucket_owner, @project.bitbucket_slug, :state => 'merged')['values']
  end

  define_method "#{ name.sub('FromBitbucket', '').downcase }_last_commit_date" do |tag|
    DateTime.parse(tag.last['utctimestamp']).utc
  end
end
