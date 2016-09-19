# Class for pull requests business logic.
class PullRequest < ActiveRecord::Base
  include Providerable

  store_accessor :meta, :github_url, :bitbucket_url, :gitlab_url, :author_url, :number_from_provider

  belongs_to :project

  belongs_to :changelog

  has_many :pull_request_subtasks, :dependent => :destroy

  has_many :pull_request_to_issue_connections, :dependent => :destroy

  has_many :issues, :through => :pull_request_to_issue_connections

  after_save :bind_to_issues

  after_save :fetch_or_create_subtasks

  validates :title, :id_from_provider, :length => { :maximum => Settings.max_string_field_size },
    :presence => true

  validates :merged_at, :presence => true

  def url_from_provider
    send("#{ provider }_url")
  end

  def handle_for_changelog(changelog, pull_request_info, project)
    assign_attributes({ :changelog => changelog, :project => project }.merge(pull_request_info))

    save!
  end

  # There are some problems to define merged at date for gitlab pull request.
  # We define it as updated at field from api for gitlab, so we suppose it won't change in the future.
  def not_handle_for_changelog?
    persisted? && provider == 'gitlab' && changelog_id.present?
  end

  def pull_request_info_for_report
    "#{ title } ([##{ number_from_provider }](#{ url_from_provider }) " \
      "#{ I18n.t 'changelogs.changelog.by' } [@#{ created_by }](#{ author_url }))\n"
  end

  private

  def scan_body_and_bind_to_issue(binding_word)
    body.to_s.scan(Regexp.new("#{ binding_word }\\s+\\w*#+\\d+")) do |connection|
      bind_to_issue(connection.split('#').last)
    end
  end

  def bind_to_issues
    Settings.issue_binding_words.each { |binding_word| scan_body_and_bind_to_issue(binding_word) }
  end

  def fetch_or_create_subtasks
    fetched_subtask_ids = body.to_s.scan(/^[0-9]*\.*\s*\[\w*\]+.*/).map do |subtask_content|
      pull_request_subtasks.where(parse_subtask_content(subtask_content)).first_or_create
    end.compact.map(&:id)

    pull_request_subtasks.where.not(:id => fetched_subtask_ids).destroy_all
  end

  def parse_subtask_content(subtask_content)
    {
      :description => PullRequestUtilities.description_from_fetched_data(subtask_content),
      :story_points => PullRequestUtilities.story_points_from_fetched_data(subtask_content),
      :task_type => PullRequestUtilities.task_type_from_fetched_data(subtask_content),
      :changelog_id => changelog.try(&:id)
    }
  end

  def bind_to_issue(number_from_provider)
    issue = project.issues.find_by("meta ->> '#{ number_field }' = '?'", number_from_provider.to_i)

    pull_request_to_issue_connections.where(:issue => issue).first_or_create! if issue.present?
  end

  def number_field
    project_provider = project.provider

    project_provider.in?(%w(github gitlab)) ? "#{ project_provider }_issue_number" : 'bitbucket_issue_id'
  end
end
