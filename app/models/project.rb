class Project < ActiveRecord::Base
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

  validates :name, :length => { :maximum => Settings.max_string_field_size }, :presence => true

  after_save :update_issues

  def parse_issue_params_from_github_webhook(params)
    issue = issues.find_by("meta ->> 'github_issue_id' = '?'", params[:id].to_i)

    issue = issues.build.tap { |i| i.github_issue_id = params[:id].to_i } unless issue.present?

    issue.assign_attributes_from_github_hook(params)

    issue.save!
  end

  def parse_issue_params_from_bitbucket_webhook(params)
    issue = issues.find_by("meta ->> 'bitbucket_issue_id' = '?'", params[:id])

    issue = issues.build.tap { |i| i.github_issue_id = params[:id] } unless issue.present?

    issue.assign_attributes(
      :title => params[:title],
      :body => params[:content][:raw]
    )

    issue.save!
  end

  def parse_issue_params_from_gitlab_webhook(params)
    issue = issues.find_by("meta ->> 'gitlab_issue_id' = '?'", params[:id].to_i)

    issue = issues.build.tap { |i| i.gitlab_issue_id = params[:id].to_i } unless issue.present?

    issue.assign_attributes(:title => params[:title], :body => params[:description])

    issue.save!
  end

  def create_gitlab_hook(client)
    hook = fetch_hook_from_gitlab(client)

    create_hook_to_gitlab(client) unless hook.present?
  end

  def create_github_hook(client)
    hook = fetch_hook_from_github(client)

    create_hook_to_github(client) unless hook.present?
  end

  def create_bitbucket_hook(authentication)
    unless bitbucket_secret_token_for_hook.present?
      update_attribute(:bitbucket_secret_token_for_hook, SecureRandom.hex(20))
    end

    result = list_bitbucket_hooks(authentication)

    create_bitbucket_hook_with_authentication(authentication) if create_bitbucket_hook?(result)
  end

  def fetch_hook_from_github(client)
    client.hooks(github_full_name).select do |hook|
      hook.config[:url] == Rails.application.routes.url_helpers.
        payload_from_github_project_url(id, :host => Settings.webhook_host)
    end.first
  end

  def create_hook_to_github(client)
    client.create_hook(github_full_name, 'web',
      { :url => Rails.application.routes.url_helpers.
        payload_from_github_project_url(id, :host => Settings.webhook_host),
        :secret => github_secret_token_for_hook, :content_type => 'json' },
      :events => ['issues'])
  end

  def fetch_hook_from_gitlab(client)
    client.project_hooks(gitlab_repository_id).select do |hook|
      hook.url == Rails.application.routes.url_helpers.
        payload_from_gitlab_project_url(id, :secure_token => gitlab_secret_token_for_hook,
          :host => Settings.webhook_host)
    end.first
  end

  def create_hook_to_gitlab(client)
    client.add_project_hook(gitlab_repository_id, Rails.application.routes.url_helpers.
      payload_from_gitlab_project_url(id, :secure_token => gitlab_secret_token_for_hook,
        :host => Settings.webhook_host), :issues_events => 1, :push_events => 0)
  end

  def open_issues
    issues.where(:state => 'open').size
  end

  def fetch_issue_from_github_id(github_issue_id)
    issue = issues.find_by("meta ->> 'github_issue_id' = '?'", github_issue_id)

    issue.present? ? issue : issues.build.tap { |i| i.github_issue_id = github_issue_id }
  end

  def check_bitbucket_owner(repo, client)
    repo.owner == client.user_api.profile.dig(:user, :username) ? 'owner' : 'member'
  end

  def check_gitlab_owner(repo, client)
    repo.owner.name == client.user.name ? 'owner' : 'member'
  end

  def check_github_owner(repo, _client)
    repo.permissions[:admin] == true ? 'owner' : 'member'
  end

  def list_bitbucket_hooks(authentication)
    BitBucket::Repos::Webhooks.new(:oauth_token => authentication.token,
      :oauth_secret => authentication.secret,
      :client_secret => Settings.omniauth.bitbucket.secret,
      :client_id => Settings.omniauth.bitbucket.key).list(bitbucket_owner, bitbucket_slug)
  end

  def create_bitbucket_hook_with_authentication(authentication)
    BitBucket::Repos::Webhooks.new(:oauth_token => authentication.token,
      :oauth_secret => authentication.secret).create(bitbucket_owner,
        bitbucket_slug, :description => 'kanbanonrails',
        :url => Rails.application.routes.url_helpers.
          payload_from_bitbucket_project_url(id,
            :secure_token => bitbucket_secret_token_for_hook,
            :host => Settings.webhook_host), :events => ['issue:created', 'issue:updated'],
          :active => true)
  end

  class << self
    def sync_with_github_project(repo)
      project = Project.find_by("meta ->> 'github_repository_id' = '?'", repo.id)

      project = Project.new.tap { |p| p.github_repository_id = repo.id } unless project.present?

      project.tap { |item| item.assign_attributes_from_github(repo) }
    end

    def sync_with_gitlab_project(repo)
      project = Project.find_by("meta ->> 'gitlab_repository_id' = '?'", repo.id)

      project = Project.new.tap { |p| p.gitlab_repository_id = repo.id } unless project.present?

      project.tap { |item| item.assign_attributes_from_gitlab(repo) }
    end

    def sync_with_bitbucket_project(repo)
      project = Project.find_by("meta ->> 'bitbucket_full_name' = ?", [repo.owner, repo.slug].join('/'))

      unless project.present?
        project = Project.new.tap { |p| p.bitbucket_full_name = [repo.owner, repo.slug].join('/') }
      end

      project.tap { |item| item.assign_attributes_from_bitbucket(repo) }
    end
  end

  def assign_attributes_from_bitbucket(repo)
    assign_attributes(
      :name => repo.name,
      :bitbucket_name => repo.name,
      :bitbucket_slug => repo.slug,
      :bitbucket_owner => repo.owner,
      :is_bitbucket_repository => true
    )
  end

  def assign_attributes_from_gitlab(repo)
    assign_attributes(
      :name => repo.name,
      :gitlab_name => repo.name,
      :gitlab_url => repo.web_url,
      :gitlab_full_name => repo.path_with_namespace,
      :is_gitlab_repository => true
    )
  end

  def assign_attributes_from_github(repo)
    update_attributes(
      :name => repo.name,
      :github_name => repo.name,
      :github_url => repo.html_url,
      :github_full_name => repo.full_name,
      :is_github_repository => true
    )
  end

  private

  def update_issues
    issues.map(&:save)
  end

  def create_bitbucket_hook?(result)
    !result[:values].present? || !result[:values].select { |h| h[:description] == 'kanbanonrails' }.present?
  end
end
