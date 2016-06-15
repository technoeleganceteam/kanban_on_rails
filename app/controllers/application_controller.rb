class ApplicationController < ActionController::Base
  protect_from_forgery :with => :exception

  before_action :configure_permitted_parameters, :if => :devise_controller?

  before_action :set_locale

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up).concat([:name, :locale])
  end

  def after_sign_in_path_for(resource)
    dashboard_user_url(resource)
  end

  private

  def default_url_options(options = {})
    user_signed_in? ? options : { :locale => I18n.locale }.merge(options)
  end

  def set_locale
    I18n.locale = if check_unset_locale
      http_accept_language.compatible_language_from(I18n.available_locales)
    else
      fetch_existing_locale || I18n.default_locale
    end

    manage_user_and_session_locale
  end

  def manage_user_and_session_locale
    session[:locale] = I18n.locale

    if user_signed_in? && I18n.locale.to_s != current_user.locale
      current_user.update_attributes(:locale => I18n.locale)
    end
  end

  def fetch_existing_locale
    return params[:locale] if params[:locale].present?

    return current_user.locale if user_signed_in?

    return session[:locale] if session[:locale].present?
  end

  def check_unset_locale
    !user_signed_in? && !params[:locale].present? && !session[:locale].present?
  end
end
