class Authentication < ActiveRecord::Base
  belongs_to :user

  validates :provider, :uid, :token, :presence => true

  validates :user_id, :uniqueness => { :scope => [:uid, :provider] }

  validates :uid, :uniqueness => { :scope => :provider }

  accepts_nested_attributes_for :user

  after_commit :update_user_meta

  class << self
    def build_with(current_user, params)
      params ||= {}

      authentication = Authentication.
        where(:provider => params[:provider], :uid => params[:uid]).first_or_initialize

      authentication.assign_user(current_user, params[:info].try(:[], :email), params)

      authentication.tap do |a|
        a.assign_attributes(
          :meta => params.to_json,
          :token => params[:credentials].try(:[], :token),
          :secret => params[:credentials].try(:[], :secret)
        )
      end
    end
  end

  def assign_user(current_user, email, params)
    return if !current_user.present? && !email.present?

    fetched_user = User.where(:email => email).first

    user = current_user.present? ? current_user : build_or_assign_user(fetched_user, email, params)

    user.assign_social_info(params)

    self.user = user
  end

  private

  def build_or_assign_user(fetched_user, email, _params)
    fetched_user.present? ? fetched_user : (user.present? ? user :
      build_user(:password => Devise.friendly_token[0, 10], :email => email))
  end

  def update_user_meta
    user.has_github_account = (user.authentications.where(:provider => 'github').size > 0) 

    user.has_bitbucket_account = (user.authentications.where(:provider => 'bitbucket').size > 0) 

    user.save
  end
end
