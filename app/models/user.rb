class User < ActiveRecord::Base
  store_accessor :meta, :sync_with_github, :sync_with_bitbucket, :has_github_account, :has_bitbucket_account,
    :sync_with_gitlab, :has_gitlab_account

  devise :database_authenticatable, :registerable, :confirmable, :async,
    :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  has_many :authentications, :dependent => :destroy

  has_many :issues, :through => :user_to_issue_connections

  has_many :user_to_issue_connections, :dependent => :destroy

  has_many :projects, :through => :user_to_project_connections

  has_many :user_to_project_connections, :dependent => :destroy

  has_many :boards, :through => :user_to_board_connections

  has_many :user_to_board_connections, :dependent => :destroy

  has_many :user_requests, :dependent => :destroy

  validates :locale, :presence => true, :inclusion => I18n.available_locales.map(&:to_s)

  validates :name, :length => { :maximum => Settings.max_string_field_size }, :presence => true

  validates :email, :email => { :mx_with_fallback => true }, :presence => true,
    :length => { :maximum => Settings.max_string_field_size }

  def gravatar_url
    "https://secure.gravatar.com/avatar/#{ Digest::MD5.hexdigest(email.downcase) }"
  end

  def avatar
    avatar_url.present? ? avatar_url : gravatar_url
  end

  def projects_from_search(query)
    projects.order('created_at DESC')

    query.present? ? projects.where('name ilike ?', "%#{ query }%") : projects
  end

  def github_client_repos(client)
    client.repos
  rescue Octokit::Unauthorized
    Rails.logger.info "Octokit::Unauthorized on get repos from user with id #{ id }"

    []
  end

  def gitlab_client_repos(client)
    client.projects.auto_paginate
  end

  def bitbucket_client_repos(client)
    client.repos.list
  rescue BitBucket::Error::Unauthorized
    Rails.logger.info "BitBucket::Error::Unauthorized on getting bitbucket repos from user id #{ id }"

    []
  end

  %w(gitlab github bitbucket).each do |provider|
    define_method "sync_#{ provider }" do
      return unless (client = send("#{ provider }_client"))

      send("sync_#{ provider }_projects", client)

      send("sync_#{ provider }_issues", client)

      send("create_#{ provider }_hook", client)

      update_attribute("sync_with_#{ provider }", false)

      broadcast_stop_sync_notification(provider)
    end

    define_method "sync_#{ provider }_projects" do |client|
      send("#{ provider }_client_repos", client).each do |repo|
        project = Project.send("sync_with_#{ provider }_project", repo)

        project.user_to_project_connections.where(:user_id => id).first_or_initialize.assign_attributes(
          :role => project.send("check_#{ provider }_owner", repo, client)
        )

        project.save!
      end
    end
  end

  def sync_gitlab_issues(client)
    projects.where("meta -> 'is_gitlab_repository' = 'true'").find_each do |project|
      client.issues(project.gitlab_repository_id).auto_paginate.each do |gitlab_issue|
        Issue.sync_with_gitlab_issue(gitlab_issue, project)
      end
    end
  end

  def create_gitlab_hook(client)
    projects.where("meta -> 'is_gitlab_repository' = 'true'").find_each do |project|
      project.create_gitlab_hook(client)
    end
  end

  def gitlab_client
    authentication = authentications.find_by(:provider => 'gitlab')

    return false unless authentication.present?

    Gitlab.endpoint = Settings.gitlab_endpoint

    Gitlab.tap { |client| client.private_token = authentication.gitlab_private_token }
  end

  def bitbucket_client
    authentication = authentications.find_by(:provider => 'bitbucket')

    return false unless authentication.present?

    BitBucket.new :oauth_token => authentication.token, :oauth_secret => authentication.secret,
      :client_secret => Settings.omniauth.bitbucket.secret, :client_id => Settings.omniauth.bitbucket.key
  end

  def sync_bitbucket_issues(client)
    projects.where("meta -> 'is_bitbucket_repository' = 'true'").find_each do |project|
      begin
        client.issues.list_repo(project.bitbucket_owner, project.bitbucket_slug).each do |bitbucket_issue|
          Issue.sync_with_bitbucket_issue(bitbucket_issue, project)
        end
      rescue BitBucket::Error::NotFound
        Rails.logger.info "BitBucket::Error::NotFound on sync bitbucket issues with project id #{ project.id }"
      end
    end
  end

  def create_bitbucket_hook(_client)
    authentication = authentications.find_by(:provider => 'bitbucket')

    return false unless authentication.present?

    projects.where("meta -> 'is_bitbucket_repository' = 'true'").find_each do |project|
      begin
        project.create_bitbucket_hook(authentication)
      rescue BitBucket::Error::Unauthorized, BitBucket::Error::Forbidden, BitBucket::Error::NotFound
        Rails.logger.info "Something wrong on creating bitbucket hooks with project id #{ project.id }"
      end
    end
  end

  def remove_hooks_from_bitbucket
    projects.where("meta -> 'is_bitbucket_repository' = 'true'").find_each do |project|
      authentication = authentications.find_by(:provider => 'bitbucket')

      return false unless authentication.present?

      project.fetch_and_remove_hook_from_bitbucket(authentication)
    end
  end

  def remove_hooks_from_gitlab
    projects.where("meta -> 'is_gitlab_repository' = 'true'").find_each do |project|
      project.fetch_and_remove_hook_from_gitlab(gitlab_client)
    end
  end

  def remove_hooks_from_github
    projects.where("meta -> 'is_github_repository' = 'true'").find_each do |project|
      project.fetch_and_remove_hook_from_github(github_client)
    end
  end

  def github_client
    authentication = authentications.find_by(:provider => 'github')

    return false unless authentication.present?

    Octokit::Client.new(:access_token => authentication.token, :auto_paginate => true)
  end

  def sync_github_issues(client)
    projects.where("meta -> 'is_github_repository' = 'true'").find_each do |project|
      begin
        client.list_issues(project.github_full_name).each do |github_issue|
          Issue.sync_with_github_issue(github_issue, project)
        end
      rescue Octokit::NotFound, Octokit::Unauthorized
        Rails.logger.info "Octokit error while syncing issues from project id #{ project.id }"
      end
    end
  end

  def create_github_hook(client)
    projects.where("meta -> 'is_github_repository' = 'true'").find_each do |project|
      begin
        project.create_github_hook(client)
      rescue Octokit::NotFound, Octokit::Unauthorized
        Rails.logger.info "Octokit error on creating hook with project id #{ project.id }"
      end
    end
  end

  def assign_social_info(params = {})
    info = params[:info]

    self.name ||= info.try(:name) || info.try(:nickname)

    self.name = 'Name' unless self.name.present?

    self.avatar_url ||= info.try(:image)

    self.confirmed_at ||= DateTime.now.utc if info.try(:[], :email).present?
  end

  private

  def broadcast_stop_sync_notification(provider)
    ActionCable.server.broadcast "user_notifications_#{ id }",
      :type => :stop_sync_notification,
      :provider => provider,
      :body => "#{ provider } has been synced",
      :title => provider,
      :title_with_body_html => "#{ provider } has been synced"
  end
end
