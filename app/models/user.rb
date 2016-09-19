# Class for users business logic
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

  def github_client_repos
    github_client.repos
  rescue Octokit::Unauthorized
    Rails.logger.info "Octokit::Unauthorized on get repos from user with id #{ id }"

    []
  end

  def gitlab_client_repos
    gitlab_client.projects.auto_paginate
  end

  def bitbucket_client_repos
    bitbucket_client.repos.list
  rescue BitBucket::Error::Unauthorized
    Rails.logger.info "BitBucket::Error::Unauthorized on getting bitbucket repos from user id #{ id }"

    []
  end

  Settings.issues_providers.each do |provider|
    define_method "sync_from_#{ provider }" do
      return unless send("#{ provider }_client")

      send("sync_#{ provider }_projects")

      send("sync_issues_from_#{ provider }")

      send("create_#{ provider }_hook")

      update_attribute("sync_with_#{ provider }", false)

      broadcast_stop_sync_notification(provider)
    end

    define_method "sync_#{ provider }_projects" do
      send("#{ provider }_client_repos").each do |repo|
        project = Project.send("sync_with_#{ provider }_project", repo)

        project.user_to_project_connections.where(:user_id => id).first_or_initialize.assign_attributes(
          :role => ProjectUtilities.send("check_#{ provider }_owner", repo, send("#{ provider }_client"))
        )

        project.save!
      end
    end

    define_method "#{ provider }_client" do
      authentications.find_by(:provider => provider).try(&:"#{ provider }_client")
    end

    define_method "sync_issues_from_#{ provider }" do
      projects.where("meta -> 'is_#{ provider }_repository' = 'true'").find_each do |project|
        project.send("sync_issues_from_#{ provider }", send("#{ provider }_client"))
      end
    end
  end

  def create_gitlab_hook
    projects.where("meta -> 'is_gitlab_repository' = 'true'").find_each do |project|
      project.create_gitlab_hook(gitlab_client)
    end
  end

  def create_bitbucket_hook
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

  def create_github_hook
    projects.where("meta -> 'is_github_repository' = 'true'").find_each do |project|
      project.create_github_hook(github_client)
    end
  end

  def assign_social_info(params = {})
    info = params[:info]

    self.name ||= info.try(:name) || info.try(:nickname) || 'Name'

    self.avatar_url ||= info.try(:image)

    self.confirmed_at ||= DateTime.now.utc if info.try(:[], :email).present?
  end

  class << self
    def build_user(params)
      User.where(:email => params[:email]).first_or_initialize.tap do |user|
        user.name ||= params[:name]

        user.locale ||= params[:locale]
      end
    end
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
