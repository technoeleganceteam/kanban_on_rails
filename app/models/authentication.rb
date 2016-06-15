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

      authentication.assign_user(current_user, params[:info].try(:[], :email), params)

      authentication.tap { |item| item.assign_omniauth_params(params) }
    end
  end

  def assign_user(current_user, email, params)
    return if !current_user.present? && !email.present?

    fetched_user = User.find_by(:email => email)

    user = current_user.present? ? current_user : fetch_user(fetched_user, email)

    user.assign_social_info(params)

    self.user = user
  end

  def assign_omniauth_params(params)
    assign_attributes(
      :meta => params.to_json,
      :token => params[:credentials].try(:[], :token),
      :secret => params[:credentials].try(:[], :secret),
      :gitlab_private_token => params['extra'].try(:[], 'raw_info').try(:[], 'private_token')
    )
  end

  private

  def fetch_user(fetched_user, email)
    fetched_user.present? ? fetched_user : build_or_present_user(email)
  end

  def build_or_present_user(email)
    user.present? ? user : build_user(:password => Devise.friendly_token[0, 10], :email => email)
  end

  def update_user_meta
    user.update_attributes(%w(gitlab github bitbucket).map do |provider|
      ["has_#{ provider }_account", !user.authentications.where(:provider => provider).empty?]
    end.to_h)
  end
end
