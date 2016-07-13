class GenerateChangelogs
  def initialize(params = {})
    @project = params[:project]

    @provider = @project.provider

    @client = @project.send("#{ @provider }_client_for_changelogs")

    I18n.locale = @project.changelog_locale
  end

  Settings.issues_providers.each do |provider|
    define_method "#{ provider }_tag_name_and_last_commit_sha" do |tag|
      {
        :tag_name => send("#{ provider }_tag_name", tag),
        :last_commit_sha => send("#{ provider }_last_commit_sha", tag)
      }
    end
  end

  def handle_changelogs
    return unless @client.present?

    generate_changelogs

    generate_pull_requests

    changelogs = @project.changelogs.where(:handled => false)

    process_not_handled_changelogs(changelogs)

    changelogs.update_all(:handled => true)
  end

  def generate_changelogs
    send("tags_from_#{ @provider }").each { |tag| create_or_fetch_changelog(fetch_tag_info(tag)) }
  end

  def tags_from_github
    @client.tags(@project.github_full_name)
  end

  def tags_from_gitlab
    @client.tags(@project.gitlab_repository_id)
  end

  def tags_from_bitbucket
    @client.repos.tags(@project.bitbucket_owner, @project.bitbucket_slug)
  end

  def create_or_fetch_changelog(tag_info)
    @project.changelogs.where(tag_info).first_or_create!
  end

  def fetch_tag_info(tag)
    {
      :tag_name => send("#{ @provider }_tag_name", tag),
      :last_commit_sha => send("#{ @provider }_last_commit_sha", tag),
      :last_commit_date => send("fetch_#{ @provider }_last_commit_date", tag)
    }
  end

  def github_tag_name(tag)
    tag[:name]
  end

  def github_last_commit_sha(tag)
    tag[:commit][:sha]
  end

  def fetch_github_last_commit_date(tag)
    changelog = @project.changelogs.find_by(github_tag_name_and_last_commit_sha(tag))

    return changelog.last_commit_date if changelog.present?

    @client.commit(@project.github_repository_id, tag[:commit][:sha]).commit.author.date
  end

  def gitlab_tag_name(tag)
    tag.name
  end

  def gitlab_last_commit_sha(tag)
    tag.commit.id
  end

  def fetch_gitlab_last_commit_date(tag)
    DateTime.parse(tag.commit.committed_date).utc
  end

  def bitbucket_tag_name(tag)
    tag.first
  end

  def bitbucket_last_commit_sha(tag)
    tag.last['raw_node']
  end

  def fetch_bitbucket_last_commit_date(tag)
    DateTime.parse(tag.last['utctimestamp']).utc
  end

  def create_or_fetch_pull_request(pull_request_info)
    pull_request = @project.pull_requests.where(:id_from_provider => pull_request_info[:id_from_provider]).
      first_or_initialize

    changelog = @project.changelogs.where('last_commit_date >=?', pull_request_info[:merged_at]).
      order('last_commit_date ASC').first

    return if return_pull_request?(pull_request)

    handle_pull_request(pull_request, changelog, pull_request_info)
  end

  def handle_pull_request(pull_request, changelog, pull_request_info)
    pull_request.assign_attributes({ :changelog => changelog, :project => @project }.merge(pull_request_info))

    pull_request.save!
  end

  def generate_pull_requests
    send("#{ @provider }_fetch_pull_requests").each do |pull_request|
      create_or_fetch_pull_request(fetch_pull_request_info(pull_request))
    end
  end

  def fetch_pull_request_info(pull_request)
    {
      :id_from_provider => send("#{ @provider }_id_from_provider", pull_request),
      :title => send("#{ @provider }_pull_request_title", pull_request),
      :body => send("#{ @provider }_pull_request_body", pull_request),
      :merged_at => send("#{ @provider }_pull_request_merged_at", pull_request),
      :created_by => send("#{ @provider }_pull_request_created_by", pull_request),
      :author_url => send("#{ @provider }_pull_request_author_url", pull_request),
      "#{ @provider }_url" => send("#{ @provider }_pull_request_url", pull_request),
      :number_from_provider => send("#{ @provider }_pull_request_number", pull_request)
    }
  end

  def github_id_from_provider(pull_request)
    pull_request['id']
  end

  def github_pull_request_title(pull_request)
    pull_request['title']
  end

  def github_pull_request_body(pull_request)
    pull_request['body']
  end

  def github_pull_request_merged_at(pull_request)
    pull_request['merged_at']
  end

  def github_pull_request_created_by(pull_request)
    pull_request['user']['login']
  end

  def github_pull_request_author_url(pull_request)
    pull_request['user']['html_url']
  end

  def github_pull_request_url(pull_request)
    pull_request['html_url']
  end

  def github_pull_request_number(pull_request)
    pull_request['number']
  end

  def gitlab_id_from_provider(pull_request)
    pull_request.id
  end

  def gitlab_pull_request_title(pull_request)
    pull_request.title
  end

  def gitlab_pull_request_body(pull_request)
    pull_request.description
  end

  def gitlab_pull_request_merged_at(pull_request)
    # We don't know about when merge request was merged from gitlab,
    # we can only get merge request updated at(https://github.com/gitlabhq/gitlabhq/blob/dad406da23f7a4d94f9f8df1a4b8743dc0e9dc96/lib/gitlab/github_import/pull_request_formatter.rb#L95)
    # and consider it as merged at date.
    # But often it is about 5 seconds later than it was realy merged.
    # If you know how to improve that method, please contact me or send PR.
    DateTime.parse(pull_request.updated_at).utc - 5.seconds
  end

  def gitlab_pull_request_created_by(pull_request)
    pull_request.author.username
  end

  def gitlab_pull_request_author_url(pull_request)
    pull_request.author.web_url
  end

  def gitlab_pull_request_url(pull_request)
    "#{ Settings.gitlab_base_url }/#{ @project.gitlab_full_name }/merge_requests/#{ pull_request.iid }"
  end

  def gitlab_pull_request_number(pull_request)
    pull_request.iid
  end

  def bitbucket_id_from_provider(pull_request)
    pull_request.id
  end

  def bitbucket_pull_request_title(pull_request)
    pull_request.title
  end

  def bitbucket_pull_request_body(pull_request)
    pull_request.description
  end

  def bitbucket_pull_request_merged_at(pull_request)
    DateTime.parse(@client.repos.commit.list(@project.bitbucket_owner,
      @project.bitbucket_slug, pull_request['merge_commit']['hash'])['date']).utc
  end

  def bitbucket_pull_request_created_by(pull_request)
    pull_request.author.username
  end

  def bitbucket_pull_request_author_url(pull_request)
    pull_request.author['links']['html']['href']
  end

  def bitbucket_pull_request_url(pull_request)
    pull_request['links']['html']['href']
  end

  def bitbucket_pull_request_number(pull_request)
    pull_request.id
  end

  def github_fetch_pull_requests
    @client.pull_requests(@project.github_full_name, :state => 'closed')
  end

  def gitlab_fetch_pull_requests
    @client.merge_requests(@project.gitlab_repository_id, :state => 'merged')
  end

  def bitbucket_fetch_pull_requests
    @client.repos.pull_request.
      list(@project.bitbucket_owner, @project.bitbucket_slug, :state => 'merged')['values']
  end

  def process_not_handled_changelogs(changelogs)
    return unless changelogs.any?

    ProjectMailer.changelogs_email(changelogs.map(&:id)).deliver_later if @project.emails_for_reports.any?

    changelogs.each(&:close_issues) if @project.close_issues?

    @project.write_changelog if @project.write_changelog_to_repository?
  end

  private

  # There are some problems to define merged at date for gitlab pull request.
  # We define it as updated at field from api for gitlab, so we suppose it won't change in the future.
  def return_pull_request?(pull_request)
    pull_request.persisted? && pull_request.provider == 'gitlab' && pull_request.changelog_id.present?
  end
end
