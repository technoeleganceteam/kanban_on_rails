class PullRequest < ActiveRecord::Base
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

  def provider
    Settings.issues_providers.map { |provider| provider if send("#{ provider }_url").present? }.compact.first
  end

  def url_from_provider
    send("#{ provider }_url")
  end

  private

  def bind_to_issues
    Settings.issue_binding_words.each do |binding_word|
      body.scan(Regexp.new("#{ binding_word }\\s+\\w*#+\\d+")) do |connection|
        bind_to_issue(connection.split('#').last)
      end
    end
  end

  def fetch_or_create_subtasks
    fetched_subtask_ids = body.scan(/^[0-9]*\.*\s*\[\w*\]+.*/).map do |subtask_content|
      pull_request_subtasks.where(parse_subtask_content(subtask_content)).first_or_create
    end.compact.map(&:id)

    pull_request_subtasks.where.not(:id => fetched_subtask_ids).destroy_all
  end

  def parse_subtask_content(subtask_content)
    {
      :description => description_from_fetched_data(subtask_content),
      :story_points => story_points_from_fetched_data(subtask_content),
      :task_type => task_type_from_fetched_data(subtask_content),
      :changelog_id => changelog.try(&:id)
    }
  end

  def description_from_fetched_data(subtask_content)
    /[0-9]*\.*\s*(\[\w*\])*(.*)/m.match(subtask_content).try(:[], -1).try(:strip).to_s
  end

  def story_points_from_fetched_data(subtask_content)
    subtask_content.scan(/^[0-9]*\.*\s*\[.*\]/m).first.to_s.
      scan(/\[\w*?\]/).try(:[], 1).to_s.sub(']', '').sub('[', '')
  end

  def task_type_from_fetched_data(subtask_content)
    subtask_content.scan(/^[0-9]*\.*\s*\[.*\]/m).first.to_s.
      scan(/\[\w*?\]/).first.to_s.sub(']', '').sub('[', '')
  end

  def bind_to_issue(number_from_provider)
    issue = project.issues.find_by("meta ->> '#{ number_field }' = '?'", number_from_provider.to_i)

    pull_request_to_issue_connections.where(:issue => issue).first_or_create! if issue.present?
  end

  def number_field
    project.provider.in?(%w(github gitlab)) ? "#{ project.provider }_issue_number" : 'bitbucket_issue_id'
  end
end
