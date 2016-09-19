# Service for generate changelogs
class GenerateChangelogs
  def initialize(params = {})
    @project = params[:project]

    @provider = @project.provider

    @client = @project.send("#{ @provider }_client_for_changelogs")

    I18n.locale = @project.changelog_locale

    provider_classify = @provider.classify

    @helper = {
      :provider_utilities => "#{ provider_classify }Utilities".constantize,
      :fetch_from_service => "FetchFrom#{ provider_classify }".constantize.
        new(:project => @project, :client => @client)
    }
  end

  def generate
    return unless @client.present?

    generate_changelogs

    generate_pull_requests

    handle_changelogs
  end

  private

  def handle_changelogs
    changelogs = @project.changelogs.where(:handled => false)

    process_not_handled_changelogs(changelogs)

    changelogs.update_all(:handled => true)
  end

  def generate_changelogs
    @helper[:fetch_from_service].tags.each { |tag| create_or_fetch_changelog(fetch_tag_info(tag)) }
  end

  def create_or_fetch_changelog(tag_info)
    @project.changelogs.where(tag_info).first_or_create!
  end

  def fetch_tag_info(tag)
    provider_utilities = @helper[:provider_utilities]
    {
      :tag_name => provider_utilities.tag_name(tag),
      :last_commit_sha => provider_utilities.last_commit_sha(tag),
      :last_commit_date => @helper[:fetch_from_service].fetch_last_commit_date(tag)
    }
  end

  def create_or_fetch_pull_request(pull_request_info)
    pull_request = @project.pull_requests.where(:id_from_provider => pull_request_info['id_from_provider']).
      first_or_initialize

    changelog = @project.changelogs.where('last_commit_date >=?', pull_request_info['merged_at']).
      order('last_commit_date ASC').first

    return if pull_request.not_handle_for_changelog?

    pull_request.handle_for_changelog(changelog, pull_request_info, @project)
  end

  def generate_pull_requests
    @helper[:fetch_from_service].pull_requests.each do |pull_request|
      create_or_fetch_pull_request(fetch_pull_request_info(pull_request))
    end
  end

  def fetch_pull_request_info(pull_request)
    provider_utilities = @helper[:provider_utilities]

    %w(id_from_provider title body created_by author_url number_from_provider).map do |field|
      [field, provider_utilities.send("pull_request_#{ field }", pull_request)]
    end.to_h.merge(
      'merged_at' => provider_utilities.pull_request_merged_at(pull_request, @client, @project),
      "#{ @provider }_url" => provider_utilities.pull_request_url(pull_request, @project)
    )
  end

  def process_not_handled_changelogs(changelogs)
    return unless changelogs.any?

    ProjectMailer.changelogs_email(changelogs.map(&:id)).deliver_later if @project.emails_for_reports.any?

    changelogs.each(&:close_issues) if @project.close_issues?

    @project.write_changelog if @project.write_changelog_to_repository?
  end
end
