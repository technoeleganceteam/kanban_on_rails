class Issue < ActiveRecord::Base
  include EmptyArrayRemovable

  store_accessor :meta, :github_issue_id, :github_issue_number, :bitbucket_issue_id,
    :github_issue_comments_count, :github_issue_html_url, :github_labels, :bitbucket_issue_comment_count,
    :gitlab_issue_id

  has_many :users, :through => :user_to_issue_connections

  has_many :user_to_issue_connections, :dependent => :destroy

  belongs_to :project, :counter_cache => true

  has_many :boards, :through => :issue_to_section_connections

  has_many :sections, :through => :issue_to_section_connections

  has_many :columns, :through => :issue_to_section_connections

  has_many :issue_to_section_connections, :dependent => :destroy

  validates :title, :length => { :maximum => Settings.max_string_field_size }, :presence => true

  validates :body, :length => { :maximum => Settings.max_text_field_size }, :allow_blank => true

  validates :project_id, :presence => true

  validates :state, :presence => true, :inclusion => ['closed', 'open']

  before_create :assign_issue_to_section_connections

  before_update :check_section_connections

  def assign_issue_to_section_connections
    Section.where(:board_id => project.boards).where('ARRAY[?]::varchar[] && tags', tags).each do |section|
      build_section_connection(section)
    end

    Section.where(:board_id => project.boards).where(:include_all => true).each do |section|
      build_section_connection(section)
    end
  end

  def parse_tags(source_column_id, target_column_id)
    tags - (Column.where(:id => source_column_id.to_i).first.try(:tags).to_a & tags) +
      Column.where(:id => target_column_id.to_i).first.try(:tags).to_a
  end

  def sync_with_github(user_id)
    user = User.where(:id => user_id).first

    return unless user.present?

    client = user.github_client

    return unless client.present?

    if github_issue_number.present?
      client.update_issue(project.github_full_name, github_issue_number,
        :title => title, :body => body, :labels => tags)
    else
      result = client.create_issue(project.github_full_name, title, body, :labels => tags)

      update_attributes(:github_issue_id => result.try(:id),
        :github_issue_number => result.try(:number),
        :github_issue_comments_count => result.try(:comments),
        :github_issue_html_url => result.try(:html_url),
        :github_labels => result.try(:labels))
    end
  end

  def sync_with_bitbucket(user_id)
    user = User.where(:id => user_id).first

    return unless user.present?

    client = user.bitbucket_client

    return unless client.present?

    if bitbucket_issue_id.present?
      client.issues.edit(project.bitbucket_owner, project.bitbucket_slug, bitbucket_issue_id,
        'title' => title, 'content' => body)
    else
      result = client.issues.create(project.bitbucket_owner, project.bitbucket_slug, { 'title' => title })

      update_attributes!(:bitbucket_issue_id => result.id)
    end
  end

  def sync_with_gitlab(user_id)
    user = User.where(:id => user_id).first

    return unless user.present?

    client = user.gitlab_client

    return unless client.present?

    if gitlab_issue_id.present?
      client.edit_issue(project.gitlab_repository_id, gitlab_issue_id, { :title => title,
        :description => body, :labels => tags.join(',') })
    else
      result = client.create_issue(project.gitlab_repository_id, title,
        { :description => body, :labels => tags.join(',') })

      update_attributes!(:gitlab_issue_id => result.id)
    end
  end

  def parse_attributes_for_update(attributes)
    { :id => attributes[:id], :tags => parse_tags(attributes[:source_column_id], attributes[:target_column_id]) }
  end

  class << self
    def user_change_issue(issue_id, user_id)
      issue = Issue.where(:id => issue_id).first

      return unless issue.present?

      SyncGithubIssueWorker.perform_async(issue_id, user_id) if issue.project.is_github_repository

      SyncBitbucketIssueWorker.perform_async(issue_id, user_id) if issue.project.is_bitbucket_repository

      SyncGitlabIssueWorker.perform_async(issue_id, user_id) if issue.project.is_gitlab_repository

      NotificationWorker.perform_async(issue_id, user_id)
    end
  end

  private

  def build_section_connection(section)
    column = Column.where(:board_id => project.boards).where('ARRAY[?]::varchar[] && tags', tags).first

    return unless column.present?

    connection = issue_to_section_connections.where(:board_id => column.board_id, :section_id => section.id).
      first_or_initialize

    connection.issue_order = column.max_order(section) + 1

    connection.column_id = column.id

    self.issue_to_section_connections << connection
  end

  def check_section_connections
    assign_issue_to_section_connections    
  end
end
