# Class for project business logic
class Project < ActiveRecord::Base
  include Viewable

  store_accessor :meta, :github_repository_id, :github_name, :github_full_name,
    :is_github_repository, :is_bitbucket_repository, :bitbucket_name, :bitbucket_owner,
    :bitbucket_slug, :bitbucket_full_name, :github_secret_token_for_hook, :bitbucket_secret_token_for_hook,
    :github_url, :gitlab_url, :gitlab_repository_id, :gitlab_name, :gitlab_full_name, :is_gitlab_repository,
    :gitlab_secret_token_for_hook

  has_many :users, :through => :user_to_project_connections

  has_many :user_to_project_connections, :dependent => :destroy

  has_many :issues, :dependent => :destroy

  has_many :sections, :dependent => :destroy

  has_many :columns, :dependent => :destroy

  has_many :issue_to_section_connections

  has_many :boards, :through => :project_to_board_connections

  has_many :project_to_board_connections, :dependent => :destroy

  has_many :pull_requests, :dependent => :destroy

  has_many :changelogs, :dependent => :destroy

  validates :name, :changelog_filename,
    :length => { :maximum => Settings.max_string_field_size }, :presence => true

  validates :changelog_locale, :presence => true, :inclusion => I18n.available_locales.map(&:to_s)

  after_save :update_issues

  Settings.issues_providers.each do |provider|
    define_method "fetch_and_remove_hook_from_#{ provider }" do |client|
      hook = send("fetch_hook_from_#{ provider }", client)

      send("remove_hook_from_#{ provider }", client, hook) if hook.present?
    end

    define_method "create_#{ provider }_hook" do |client|
      unless send("#{ provider }_secret_token_for_hook").present?
        update_attributes("#{ provider }_secret_token_for_hook" => SecureRandom.hex(20))
      end

      save

      hook = send("fetch_hook_from_#{ provider }", client)

      send("create_hook_to_#{ provider }", client) unless hook.present?
    end

    define_method "payload_from_#{ provider }_url" do
      Rails.application.routes.url_helpers.
        send("payload_from_#{ provider }_project_url", id, :host => Settings.webhook_host)
    end

    define_method "parse_issue_params_from_#{ provider }_webhook" do |params|
      issue = issues.find_by("meta ->> '#{ provider }_issue_id' = '?'", params[:id].to_i)

      unless issue.present?
        issue = issues.build.tap { |item| item.send("#{ provider }_issue_id=", params[:id].to_i) }
      end

      issue.send("assign_attributes_from_#{ provider }_hook", params)

      issue.save!
    end

    define_method "#{ provider }_client_for_changelogs" do
      owners = user_to_project_connections.includes(:user).where(:role => 'owner').order('created_at ASC')

      authentication = owners.each do |owner|
        result = Authentication.find_by(:user_id => owner.user, :provider => provider)

        break result if result.present?
      end

      authentication.user.send("#{ provider }_client") if authentication.present? && authentication.class != Array
    end

    define_method "assign_attributes_from_#{ provider }" do |repo|
      assign_attributes({
        :name => repo.name,
        "#{ provider }_name" => repo.name,
        "is_#{ provider }_repository" => true
      }.merge(ProjectUtilities.send("#{ provider }_special_attributes", repo)))
    end

    define_method "sync_from_#{ provider }_issue" do |provider_issue|
      id_param = provider == 'bitbucket' ? 'local_id' : 'id'

      issue = issues.find_by("meta ->> '#{ provider }_issue_id' = '?'",
        provider_issue.send(id_param).to_i)

      unless issue.present?
        issue = issues.build.tap do |item|
          item.send("#{ provider }_issue_id=", provider_issue.send(id_param))
        end
      end

      issue.send("assign_attributes_from_#{ provider }_api", provider_issue)

      issue.save!
    end
  end

  def write_changelog
    file_content = view.render(:partial => 'changelogs/changelog_raw_md',
      :collection => changelogs.order('last_commit_date DESC'), :as => :changelog)

    file_content.prepend("# #{ changelog_filename }\n")

    commit_message = "#{ I18n.t 'update_changelog_up_to' } #{ changelogs.first.tag_name }"

    send("write_changelog_to_#{ provider }_repository", file_content, commit_message)
  end

  def sync_issues_from_github(client)
    client.list_issues(github_full_name).each do |github_issue|
      sync_from_github_issue(github_issue)
    end
  rescue Octokit::NotFound, Octokit::Unauthorized
    Rails.logger.info "Octokit error while syncing issues from project id #{ id }"
  end

  def sync_issues_from_gitlab(client)
    client.issues(gitlab_repository_id).auto_paginate.each do |gitlab_issue|
      sync_from_gitlab_issue(gitlab_issue)
    end
  end

  def sync_issues_from_bitbucket(client)
    client.issues.list_repo(bitbucket_owner, bitbucket_slug).each do |bitbucket_issue|
      sync_from_bitbucket_issue(bitbucket_issue)
    end
  rescue BitBucket::Error::NotFound
    Rails.logger.info "BitBucket::Error::NotFound on sync bitbucket issues with project id #{ id }"
  end

  def write_changelog_to_github_repository(file_data, commit_message)
    content = github_client_for_changelogs.contents(github_repository_id, :path => "#{ changelog_filename }.md")

    github_client_for_changelogs.update_contents(github_repository_id, "#{ changelog_filename }.md",
      commit_message, content.sha, file_data)
  rescue Octokit::NotFound
    github_client_for_changelogs.create_contents(github_repository_id, "#{ changelog_filename }.md",
      commit_message, file_data)
  end

  def write_changelog_to_gitlab_repository(file_data, commit_message)
    gitlab_client_for_changelogs.get_file(gitlab_repository_id, "#{ changelog_filename }.md", 'master')

    gitlab_client_for_changelogs.edit_file(gitlab_repository_id, "#{ changelog_filename }.md",
      'master', file_data, commit_message)
  rescue Gitlab::Error::NotFound
    gitlab_client_for_changelogs.create_file(gitlab_repository_id, "#{ changelog_filename }.md",
      'master', file_data, commit_message)
  end

  def write_changelog_to_bitbucket_repository(_file_date, _commit_message)
    # This feature is not available in the gem for bitbucket api https://github.com/bitbucket-rest-api/bitbucket
    # You can send PR to this gem or propose better gem for bitbucket api
  end

  def parse_params_from_github_webhook(params)
    issue_params = params[:issue]

    parse_issue_params_from_github_webhook(issue_params) if issue_params.present?

    GenerateChangelogsWorker.perform_async(id) if params[:ref_type] == 'tag' && generate_changelogs?
  end

  def parse_params_from_gitlab_webhook(params)
    object_kind = params[:object_kind]

    parse_issue_params_from_gitlab_webhook(params[:object_attributes]) if object_kind == 'issue'

    GenerateChangelogsWorker.perform_async(id) if object_kind == 'tag_push' && generate_changelogs?
  end

  def parse_params_from_bitbucket_webhook(params)
    issue_params = params[:issue]

    parse_issue_params_from_bitbucket_webhook(issue_params) if issue_params.present?

    if params.dig(:push, :changes).present? && params[:push][:changes].first.dig(:new, :type) == 'tag'
      GenerateChangelogsWorker.perform_async(id) if generate_changelogs?
    end
  end

  def provider
    Settings.issues_providers.map do |provider|
      provider if send("is_#{ provider }_repository")
    end.compact.first
  end

  def fetch_and_create_github_issue(github_issue_number)
    info = github_client_for_changelogs.issue(github_repository_id, github_issue_number)

    sync_from_github_issue(info)
  end

  def fetch_and_create_gitlab_issue(gitlab_issue_id)
    info = gitlab_client_for_changelogs.issue(gitlab_repository_id, gitlab_issue_id)

    sync_from_gitlab_issue(info)
  end

  def fetch_and_create_bitbucket_issue(bitbucket_issue_id)
    info = bitbucket_client_for_changelogs.issues.get(bitbucket_owner, bitbucket_slug, bitbucket_issue_id)

    sync_from_bitbucket_issue(info)
  end

  def remove_hook_from_bitbucket(authentication, hook)
    BitBucket::Repos::Webhooks.new(:oauth_token => authentication.token,
      :oauth_secret => authentication.secret).delete(bitbucket_owner,
        bitbucket_slug, hook.uuid[1...-1])
  end

  def remove_hook_from_gitlab(client, hook)
    client.delete_project_hook(gitlab_repository_id, hook.id)
  end

  def remove_hook_from_github(client, hook)
    client.remove_hook(github_full_name, hook.id)
  end

  def fetch_hook_from_github(client)
    client.hooks(github_full_name).find do |hook|
      hook.config[:url] == payload_from_github_url
    end
  rescue Octokit::NotFound, Octokit::Unauthorized
    Rails.logger.info "Octokit error on fetch hooks from project id #{ id }"

    false
  end

  def fetch_hook_from_bitbucket(authentication)
    result = list_bitbucket_hooks(authentication)

    result[:values].find { |hash| hash[:description] == 'kanbanonrails' }
  rescue BitBucket::Error::Forbidden, BitBucket::Error::NotFound
    Rails.logger.info "BitBucket error on get hooks from project id #{ id }"

    false
  end

  def fetch_hook_from_gitlab(client)
    client.project_hooks(gitlab_repository_id).find do |hook|
      hook.url == Rails.application.routes.url_helpers.
        payload_from_gitlab_project_url(id, :secure_token => gitlab_secret_token_for_hook,
          :host => Settings.webhook_host)
    end
  end

  def create_hook_to_github(client)
    client.create_hook(github_full_name, 'web',
      { :url => Rails.application.routes.url_helpers.
        payload_from_github_project_url(id, :host => Settings.webhook_host),
        :secret => github_secret_token_for_hook, :content_type => 'json' },
      :events => ['*'])
  rescue Octokit::NotFound, Octokit::Unauthorized
    Rails.logger.info "Octokit error on creating hook with project id #{ id }"
  end

  def create_hook_to_gitlab(client)
    client.add_project_hook(gitlab_repository_id, Rails.application.routes.url_helpers.
      payload_from_gitlab_project_url(id, :secure_token => gitlab_secret_token_for_hook,
        :host => Settings.webhook_host), :push_events => 1, :issues_events => 1,
        :merge_requests_events => 1, :tag_push_events => 1)
  end

  def create_hook_to_bitbucket(authentication)
    BitBucket::Repos::Webhooks.new(:oauth_token => authentication.token,
      :oauth_secret => authentication.secret).create(bitbucket_owner,
        bitbucket_slug, :description => 'kanbanonrails',
        :url => Rails.application.routes.url_helpers.
          payload_from_bitbucket_project_url(id,
            :secure_token => bitbucket_secret_token_for_hook,
            :host => Settings.webhook_host), :events => bitbucket_hook_events,
          :active => true)
  end

  def open_issues
    issues.where(:state => 'open').size
  end

  def list_bitbucket_hooks(authentication)
    webhooks_client = authentication.bitbucket_webhooks_client

    return unless webhooks_client.present?

    webhooks_client.list(bitbucket_owner, bitbucket_slug)
  end

  class << self
    %w(github gitlab).each do |provider|
      define_method "sync_with_#{ provider }_project" do |repo|
        project = Project.find_by("meta ->> ? = '?'", "#{ provider }_repository_id", repo.id)

        unless project.present?
          project = Project.new.tap { |item| item.send("#{ provider }_repository_id=", repo.id) }
        end

        project.tap { |item| item.send("assign_attributes_from_#{ provider }", repo) }
      end
    end

    def sync_with_bitbucket_project(repo)
      full_name = [repo.owner, repo.slug].join('/')

      project = Project.find_by("meta ->> 'bitbucket_full_name' = ?", full_name)

      project = Project.new(:bitbucket_full_name => full_name) unless project.present?

      project.tap { |item| item.assign_attributes_from_bitbucket(repo) }
    end
  end

  private

  def update_issues
    issues.map(&:save)
  end

  def bitbucket_hook_events
    [
      'repo:push', 'repo:fork', 'repo:commit_comment_created', 'repo:commit_status_created',
      'repo:commit_status_updated', 'issue:created', 'issue:updated', 'issue:comment_created',
      'pullrequest:created', 'pullrequest:updated', 'pullrequest:approved', 'pullrequest:unapproved',
      'pullrequest:fulfilled', 'pullrequest:rejected', 'pullrequest:comment_created',
      'pullrequest:comment_updated', 'pullrequest:comment_deleted'
    ]
  end
end
