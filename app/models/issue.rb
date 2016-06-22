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

  validates :state, :presence => true, :inclusion => %w(closed open)

  after_save :assign_issue_to_section_connections

  def assign_issue_to_section_connections
    Section.where(:board_id => project.boards).where('ARRAY[?]::varchar[] && tags', tags).find_each do |section|
      build_section_connection(section)
    end

    Section.where(:board_id => project.boards).where(:include_all => true).find_each do |section|
      build_section_connection(section)
    end
  end

  def parse_tags(source_column_id, target_column_id)
    tags - (Column.find_by(:id => source_column_id.to_i).try(:tags).to_a & tags) +
      Column.find_by(:id => target_column_id.to_i).try(:tags).to_a
  end

  %w(gitlab github bitbucket).each do |provider|
    define_method "sync_with_#{ provider }" do |user_id|
      user = User.find_by(:id => user_id)

      return unless user.present?

      client = user.send("#{ provider }_client")

      return unless client.present?

      send("create_or_update_issue_to_#{ provider }", client)
    end
  end

  def create_or_update_issue_to_github(client)
    if github_issue_number.present?
      github_update_issue(client)
    else
      result = github_create_issue(client)

      update_attributes!(:github_issue_id => result.try(:id),
        :github_issue_number => result.try(:number),
        :github_issue_comments_count => result.try(:comments),
        :github_issue_html_url => result.try(:html_url),
        :github_labels => result.try(:labels))
    end
  end

  def create_or_update_issue_to_bitbucket(client)
    if bitbucket_issue_id.present?
      bitbucket_update_issue(client)
    else
      result = bitbucket_create_issue(client)

      update_attributes!(:bitbucket_issue_id => result.id)
    end
  end

  def create_or_update_issue_to_gitlab(client)
    if gitlab_issue_id.present?
      gitlab_update_issue(client)
    else
      result = gitlab_create_issue(client)

      update_attributes!(:gitlab_issue_id => result.id) if result.present? && result.id.present?
    end
  end

  def gitlab_update_issue(client)
    client.edit_issue(project.gitlab_repository_id, gitlab_issue_id, :title => title,
      :description => body, :labels => tags.join(','))
  end

  def gitlab_create_issue(client)
    client.create_issue(project.gitlab_repository_id, title, :description => body, :labels => tags.join(','))
  end

  def github_create_issue(client)
    client.create_issue(project.github_full_name, title, body, :labels => tags)
  end

  def github_update_issue(client)
    client.update_issue(project.github_full_name, github_issue_number,
      :title => title, :body => body, :labels => tags)
  end

  def bitbucket_create_issue(client)
    client.issues.create(project.bitbucket_owner, project.bitbucket_slug, 'title' => title)
  rescue BitBucket::Error::NotFound
    Rails.logger.info "BitBucket::Error::NotFound on sync bitbucket issues with project id #{ project.id }"

    false
  end

  def bitbucket_update_issue(client)
    client.issues.edit(project.bitbucket_owner, project.bitbucket_slug, bitbucket_issue_id,
      'title' => title, 'content' => body)
  end

  def parse_attributes_for_update(attributes)
    { :id => attributes[:id], :tags => parse_tags(attributes[:source_column_id], attributes[:target_column_id]) }
  end

  def assign_attributes_from_github_hook(params)
    assign_attributes(
      :title => params[:title],
      :body => params[:body],
      :github_issue_comments_count => params[:comments],
      :github_issue_html_url => params[:html_url],
      :tags => params[:labels].to_a.map { |l| l[:name] },
      :github_labels => params[:labels].to_a.map(&:to_a),
      :github_issue_number => params[:number].to_i
    )
  end

  class << self
    def user_change_issue(issue_id, user_id)
      issue = Issue.find_by(:id => issue_id)

      return unless issue.present?

      SyncGithubIssueWorker.perform_async(issue_id, user_id) if issue.project.is_github_repository

      SyncBitbucketIssueWorker.perform_async(issue_id, user_id) if issue.project.is_bitbucket_repository

      SyncGitlabIssueWorker.perform_async(issue_id, user_id) if issue.project.is_gitlab_repository

      NotificationWorker.perform_async(issue_id, user_id)
    end
  end

  class << self
    def sync_with_github_issue(github_issue, project)
      project.fetch_issue_from_github_id(github_issue.id).update_attributes!(
        :title => github_issue.title[0..(Settings.max_string_field_size - 1)],
        :body => github_issue.body,
        :github_issue_comments_count => github_issue.comments,
        :github_issue_html_url => github_issue.html_url,
        :tags => github_issue.labels.map(&:name),
        :github_labels => github_issue.labels,
        :github_issue_number => github_issue.number
      )
    end

    def sync_with_bitbucket_issue(bitbucket_issue, project)
      issue = project.issues.find_by("meta ->> 'bitbucket_issue_id' = '?'", bitbucket_issue.local_id)

      unless issue.present?
        issue = project.issues.build.tap { |i| i.bitbucket_issue_id = bitbucket_issue.local_id }
      end

      issue.assign_attributes(
        :title => bitbucket_issue.title,
        :body => bitbucket_issue.content,
        :bitbucket_issue_comment_count => bitbucket_issue.comment_count
      )

      issue.save!
    end

    def sync_with_gitlab_issue(gitlab_issue, project)
      issue = project.issues.find_by("meta ->> 'gitlab_issue_id' = '?'", gitlab_issue.id)

      issue = project.issues.build.tap { |i| i.gitlab_issue_id = gitlab_issue.id } unless issue.present?

      issue.assign_attributes(
        :title => gitlab_issue.title,
        :body => gitlab_issue.description,
        :tags => gitlab_issue.labels
      )

      issue.save!
    end
  end

  private

  def build_section_connection(section)
    column = Column.where('ARRAY[?]::varchar[] && tags', tags).find_by(:board_id => section.board)

    column.build_issue_to_section_connection(section, self) if column.present?
  end
end
