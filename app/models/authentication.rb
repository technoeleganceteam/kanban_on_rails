# Class for authentication business logic
class Authentication < ActiveRecord::Base
  store_accessor :meta, :gitlab_private_token

  belongs_to :user

  validates :provider, :uid, :token, :presence => true

  validates :user_id, :uniqueness => { :scope => [:uid, :provider] }

  validates :uid, :uniqueness => { :scope => :provider }

  accepts_nested_attributes_for :user

  after_commit :update_user_meta

  class << self
    def build_with(current_user, params)
      authentication = Authentication.
        where(:provider => params[:provider], :uid => params[:uid]).first_or_initialize

      user = BuildUserForAuthentication.new(:current_user => current_user, :params => params).handle_user

      authentication.user = user if user.present?

      authentication.tap { |item| item.assign_omniauth_params(params) }
    end
  end

  def assign_omniauth_params(params)
    assign_attributes(AuthenticationUtilities.params_from_omniauth(params))
  end

  def bitbucket_client
    return false if provider != 'bitbucket'

    BitBucket.new(bitbucket_config)
  end

  def gitlab_client
    return false if provider != 'gitlab'

    Gitlab.endpoint = Settings.gitlab_endpoint

    Gitlab.tap { |client| client.private_token = gitlab_private_token }
  end

  def github_client
    return false if provider != 'github'

    Octokit::Client.new(:access_token => token, :auto_paginate => true)
  end

  def bitbucket_webhooks_client
    return false if provider != 'bitbucket'

    BitBucket::Repos::Webhooks.new(bitbucket_config)
  end

  private

  def update_user_meta
    user.update_attributes(Settings.issues_providers.map do |provider|
      ["has_#{ provider }_account", !user.authentications.where(:provider => provider).empty?]
    end.to_h)
  end

  def bitbucket_config
    bitbucket_settings = Settings.omniauth.bitbucket

    {
      :oauth_token => token,
      :oauth_secret => secret,
      :client_secret => bitbucket_settings.secret,
      :client_id => bitbucket_settings.key
    }
  end
end
