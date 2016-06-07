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
    session[:locale] = I18n.locale = if !user_signed_in? && !params[:locale].present? && !session[:locale].present?
      http_accept_language.compatible_language_from(I18n.available_locales)
    else
      params[:locale].present? ? params[:locale] : (user_signed_in? && current_user.locale.present? ?
        current_user.locale : (session[:locale].present? ? session[:locale] : I18n.default_locale))
    end

    return if !(user_signed_in? && I18n.locale.to_s != current_user.locale)

    current_user.update_attributes(:locale => I18n.locale)
  end
end
