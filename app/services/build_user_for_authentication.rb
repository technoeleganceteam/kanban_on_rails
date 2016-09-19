# Service that build user for authentication
class BuildUserForAuthentication
  def initialize(params = {})
    @current_user = params[:current_user]

    @params = params[:params]

    @email = @params[:info].try(:[], :email)
  end

  def handle_user
    return if !@current_user.present? && !@email.present?

    build_user
  end

  private

  def fetch_user(user)
    user.present? ? user : User.new(:password => Devise.friendly_token[0, 10], :email => @email)
  end

  def build_user
    user = @current_user.present? ? @current_user : fetch_user(User.find_by(:email => @email))

    user.assign_social_info(@params)

    user
  end
end
