class User < ActiveRecord::Base
  store_accessor :meta, :sync_with_github, :sync_with_bitbucket, :has_github_account, :has_bitbucket_account

  devise :database_authenticatable, :registerable, :confirmable, :async,
    :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  has_many :authentications, :dependent => :destroy

  has_many :issues, :through => :user_to_issue_connections

  has_many :user_to_issue_connections, :dependent => :destroy

  has_many :projects, :through => :user_to_project_connections

  has_many :user_to_project_connections, :dependent => :destroy

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

  def sync_bitbucket
    return unless (client = bitbucket_client).present?

    sync_bitbucket_projects(client)

    sync_bitbucket_issues(client)

    create_bitbucket_hook(client)

    self.update_attribute(:sync_with_bitbucket, false)

    send_end_sync_bitbucket_notification
  end

  def bitbucket_client
    authentication = authentications.where(:provider => 'bitbucket').first 

    return false unless authentication.present?

    BitBucket.new :oauth_token => authentication.token, :oauth_secret => authentication.secret,
      :client_secret => Settings.omniauth.bitbucket.secret, :client_id => Settings.omniauth.bitbucket.key
  end

  def sync_bitbucket_projects(client)
    client.repos.list.each do |repo|
      project = Project.where("meta ->> 'bitbucket_full_name' = ?",
        [repo.owner, repo.slug].join('/')).first

      if !project.present?
        project = Project.new.tap { |p| p.bitbucket_full_name = [repo.owner, repo.slug].join('/') }
      end

      u_t_p_c = if project.persisted? 
        project.user_to_project_connections.where(:user_id => id).first_or_initialize
      else
        project.user_to_project_connections.build(:user_id => id)
      end

      u_t_p_c.role = (repo.owner == client.user_api.profile.try(:[], 'user').try(:[], 'username')) ? 'owner' :
        'member'

      project.name ||= repo.name

      project.bitbucket_name = repo.name

      project.bitbucket_slug = repo.slug

      project.bitbucket_owner = repo.owner

      project.is_bitbucket_repository = true

      project.save!
    end
  end

  def sync_bitbucket_issues(client)
    projects.where("meta -> 'is_bitbucket_repository' = 'true'").each do |project|
      begin
        client.issues.list_repo(project.bitbucket_owner, project.bitbucket_slug).each do |bitbucket_issue|
          issue = project.issues.
            where("meta ->> 'bitbucket_issue_id' = '?'", bitbucket_issue.local_id).first 

          if !issue.present?
            issue = project.issues.build.tap { |i| i.bitbucket_issue_id = bitbucket_issue.local_id } 
          end

          issue.title = bitbucket_issue.title

          issue.body = bitbucket_issue.content

          issue.bitbucket_issue_comment_count = bitbucket_issue.comment_count

          issue.save!
        end
      rescue BitBucket::Error::NotFound
      end
    end
  end

  def create_bitbucket_hook(client)
    projects.where("meta -> 'is_bitbucket_repository' = 'true'").each do |project|
      project.bitbucket_secret_token_for_hook ||= SecureRandom.hex(20)

      project.save

      authentication = authentications.where(:provider => 'bitbucket').first 

      return false unless authentication.present?

      begin
        result = BitBucket::Repos::Webhooks.new(:oauth_token => authentication.token,
          :oauth_secret => authentication.secret,
          :client_secret => Settings.omniauth.bitbucket.secret,
          :client_id => Settings.omniauth.bitbucket.key).list(project.bitbucket_owner, project.bitbucket_slug)

        if !result[:values].present? || !result[:values].select { |h| h[:description] == 'kanbanonrails' }.present?
          BitBucket::Repos::Webhooks.new(:oauth_token => authentication.token,
            :oauth_secret => authentication.secret).create(project.bitbucket_owner,
              project.bitbucket_slug, { :description => 'kanbanonrails',
              :url => Rails.application.routes.url_helpers.
                payload_from_bitbucket_project_url(project,
                :secure_token => project.bitbucket_secret_token_for_hook,
                :host => Settings.webhook_host), :events => ['issue:created', 'issue:updated'],
                :active => true }) 
        end
      rescue BitBucket::Error::Unauthorized, BitBucket::Error::Forbidden
      end
    end
  end

  def sync_github
    return unless (client = github_client).present?

    sync_github_projects(client)

    sync_github_issues(client)

    create_github_hook(client)

    self.update_attribute(:sync_with_github, false)

    send_end_sync_github_notification
  end

  def github_client
    authentication = authentications.where(:provider => 'github').first 

    return false unless authentication.present?

    Octokit::Client.new(:access_token => authentication.token)
  end

  def sync_github_projects(client)
    client.repos.each do |repo|
      project = Project.where("meta ->> 'github_repository_id' = '?'", repo.id).first

      project = Project.new.tap { |p| p.github_repository_id = repo.id } unless project.present?

      u_t_p_c = if project.persisted? 
        project.user_to_project_connections.where(:user_id => id).first_or_initialize
      else
        project.user_to_project_connections.build(:user_id => id)
      end

      u_t_p_c.role = repo.permissions[:admin] == true ? 'owner' : 'member'

      project.name ||= repo.name

      project.github_name = repo.name

      project.github_url = repo.html_url

      project.github_full_name = repo.full_name

      project.is_github_repository = true

      project.save!
    end
  end

  def sync_github_issues(client)
    projects.where("meta -> 'is_github_repository' = 'true'").each do |project|
      client.list_issues(project.github_full_name).each do |github_issue|
        issue = project.issues.where("meta ->> 'github_issue_id' = '?'", github_issue.id).first 

        issue = project.issues.build.tap { |i| i.github_issue_id = github_issue.id } unless issue.present?

        issue.assign_attributes(
          :title => github_issue.title,
          :body => github_issue.body,
          :github_issue_comments_count => github_issue.comments,
          :github_issue_html_url => github_issue.html_url,
          :tags => github_issue.labels.map(&:name),
          :github_labels => github_issue.labels,
          :github_issue_number => github_issue.number)

        issue.save!
      end
    end
  end

  def create_github_hook(client)
    projects.where("meta -> 'is_github_repository' = 'true'").each do |project|
      project.github_secret_token_for_hook ||= SecureRandom.hex(20)

      project.save

      hook = client.hooks(project.github_full_name).select do |hook|
        hook.config[:url] == Rails.application.routes.url_helpers.
          payload_from_github_project_url(project, :host => Settings.webhook_host) 
      end.first

      client.create_hook(project.github_full_name, 'web',
        { :url => Rails.application.routes.url_helpers.
          payload_from_github_project_url(project, :host => Settings.webhook_host),
          :secret => project.github_secret_token_for_hook, :content_type => 'json' },
        { :events => ['issues'] }) unless hook.present? 
    end
  end

  def assign_social_info(params = {})
    self.name ||= params.try(:info).try(:name) || params.try(:info).try(:nickname)

    self.name = 'Name' unless self.name.present? 

    self.avatar_url ||= params.try(:info).try(:image)

    self.confirmed_at ||= DateTime.now if params[:info].try(:[], :email).present?
  end

  private

  def send_end_sync_github_notification
    broadcast_stop_sync_notification('github')
  end

  def send_end_sync_bitbucket_notification
    broadcast_stop_sync_notification('bitbucket')
  end

  def broadcast_stop_sync_notification(provider)
    ActionCable.server.broadcast "user_notifications_#{ id }",
      :type => :stop_sync_notification,
      :provider => provider,
      :body => "#{ provider } has been synced",
      :title => provider,
      :title_with_body_html => "#{ provider } has been synced"
  end
end
