class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  User.omniauth_providers.each do |provider|
    define_method provider do
      @authentication = Authentication.build_with(current_user, request.env['omniauth.auth'])

      if @authentication.save && @authentication.user.present? && @authentication.user.persisted?
        sign_in_and_redirect(@authentication.user)
      else
        redirect_to root_url
      end
    end
  end
end
