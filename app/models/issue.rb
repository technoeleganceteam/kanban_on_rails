# Class for issues business logic
class Issue < ActiveRecord::Base
  include EmptyArrayRemovable
  include Providerable

  store_accessor :meta, :github_issue_id, :github_issue_number, :bitbucket_issue_id,
    :github_issue_comments_count, :github_issue_html_url, :github_labels, :bitbucket_issue_comment_count,
    :gitlab_issue_id, :gitlab_issue_number, :bitbucket_issue_number

  has_many :users, :through => :user_to_issue_connections

  has_many :user_to_issue_connections, :dependent => :destroy

  belongs_to :project, :counter_cache => true

  has_many :boards, :through => :issue_to_section_connections

  has_many :sections, :through => :issue_to_section_connections

  has_many :columns, :through => :issue_to_section_connections

  has_many :issue_to_section_connections, :dependent => :destroy

  has_many :pull_request_to_issue_connections, :dependent => :destroy

  has_many :pull_requests, :through => :pull_request_to_issue_connections

  validates :title, :length => { :maximum => Settings.max_string_field_size }, :presence => true

  validates :body, :length => { :maximum => Settings.max_text_field_size }, :allow_blank => true

  validates :project_id, :presence => true

  validates :state, :presence => true, :inclusion => Settings.issue_states

  after_save :create_or_destroy_issue_to_section_connections

  delegate :name, :to => :project, :prefix => true

  def closed?
    state == 'closed'
  end

  def info_for_report
    "#{ title } ([##{ send("#{ provider }_issue_number") }](#{ url_from_provider }))\n"
  end

  def tag_color(tag)
    return unless github_labels.present?

    result = github_labels.select { |label| label[1].last == tag }[0]

    "background-color: ##{ result[2].last };color:black;" if result.present?
  end

  def create_or_destroy_issue_to_section_connections
    closed? ? issue_to_section_connections.destroy_all : assign_issue_to_section_connections
  end

  def assign_issue_to_section_connections
    build_connections_with_tags

    build_connections_with_include_all
  end

  def parse_tags(source_column_id, target_column_id)
    tags - (Column.find_by(:id => source_column_id.to_i).try(:tags).to_a & tags) +
      Column.find_by(:id => target_column_id.to_i).try(:tags).to_a
  end

  Settings.issues_providers.each do |provider|
    define_method "sync_to_#{ provider }" do |user_id|
      user = User.find_by(:id => user_id)

      return unless user.present?

      client = user.send("#{ provider }_client")

      return unless client.present?

      send("create_or_update_issue_to_#{ provider }", client)
    end

    define_method "assign_attributes_from_#{ provider }_hook" do |params|
      assign_attributes(IssueUtilities.send("params_from_#{ provider }_hook", params))
    end

    define_method "assign_attributes_from_#{ provider }_api" do |params|
      assign_attributes(IssueUtilities.send("params_from_#{ provider }_api", params))
    end
  end

  def provider_id?
    Settings.issues_providers.map { |provider| send("#{ provider }_issue_id") }.any?
  end

  def close_and_update_to_provider
    return unless provider_id?

    update_attributes(:state => 'closed')

    send("#{ provider }_update_issue", project.send("#{ project.provider }_client_for_changelogs"))
  end

  def url_from_provider
    case provider
    when 'github'
      github_issue_html_url
    when 'gitlab'
      "#{ Settings.gitlab_base_url }/" \
        "#{ project.gitlab_full_name }/issues/#{ gitlab_issue_number }"
    when 'bitbucket'
      "#{ Settings.bitbucket_base_url }/" \
        "#{ project.bitbucket_full_name }/issues/#{ bitbucket_issue_id }"
    end
  end

  def create_or_update_issue_to_github(client)
    if github_issue_number.present?
      github_update_issue(client)
    else
      update_attributes!(GithubUtilities.parse_params_from_update_issue(github_create_issue(client)))
    end
  end

  def create_or_update_issue_to_bitbucket(client)
    if bitbucket_issue_id.present?
      bitbucket_update_issue(client)
    else
      result = bitbucket_create_issue(client)

      result_id = result.present? ? result.try(&:id) : nil

      update_attributes!(:bitbucket_issue_id => result_id) if result_id.present?
    end
  end

  def create_or_update_issue_to_gitlab(client)
    if gitlab_issue_id.present?
      gitlab_update_issue(client)
    else
      result = gitlab_create_issue(client)

      update_attributes!(:gitlab_issue_id => result.id)
    end
  end

  def gitlab_update_issue(client)
    status = GitlabUtilities.issue_status_to_sync(self)

    client.edit_issue(project.gitlab_repository_id, gitlab_issue_id, { :title => title,
      :description => body, :labels => tags.join(',') }.merge(status))
  end

  def gitlab_create_issue(client)
    client.create_issue(project.gitlab_repository_id, title, :description => body, :labels => tags.join(','))
  end

  def github_create_issue(client)
    client.create_issue(project.github_full_name, title, body, :labels => tags)
  end

  def github_update_issue(client)
    client.update_issue(project.github_full_name, github_issue_number,
      :title => title, :body => body, :labels => tags, :state => state)
  end

  def bitbucket_create_issue(client)
    client.issues.create(project.bitbucket_owner, project.bitbucket_slug, 'title' => title)
  rescue BitBucket::Error::NotFound
    Rails.logger.info "BitBucket::Error::NotFound on sync bitbucket issues with project id #{ project.id }"

    false
  end

  def bitbucket_update_issue(client)
    status = BitbucketUtilities.issue_status_to_sync(self)

    client.issues.edit(project.bitbucket_owner, project.bitbucket_slug, bitbucket_issue_id,
      { 'title' => title, 'content' => body }.merge(status))
  end

  def run_sync_to_workers(user_id)
    Settings.issues_providers.each do |provider|
      SyncToWorker.perform_async(id, user_id, provider) if project.send("is_#{ provider }_repository")
    end

    NotificationWorker.perform_async(id, user_id)
  end

  class << self
    def user_change_issue(issue_id, user_id)
      issue = Issue.find_by(:id => issue_id)

      return unless issue.present?

      issue.run_sync_to_workers(user_id)
    end
  end

  private

  def build_section_connection(section)
    section_board = section.board

    column = Column.where('ARRAY[?]::varchar[] && tags', tags).find_by(:board_id => section_board)

    if column.present?
      column.build_issue_to_section_connection(section, self)
    else
      section_board.columns.where(:backlog => true).find_each do |backlog_column|
        backlog_column.build_issue_to_section_connection(section, self)
      end
    end
  end

  def build_connections_with_tags
    Section.where(:board_id => project.boards).includes(:board).
      where('ARRAY[?]::varchar[] && tags', tags).find_each do |section|
      build_section_connection(section)
    end
  end

  def build_connections_with_include_all
    Section.where(:board_id => project.boards).includes(:board).
      where(:include_all => true).find_each do |section|
      build_section_connection(section)
    end
  end
end
