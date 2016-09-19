# Controller for override create action(because of recaptcha) of Devise::RegistrationsController
class RegistrationsController < Devise::RegistrationsController
  def create
    if verify_recaptcha
      super
    else
      build_resource(sign_up_params)

      resource.valid?

      clean_up_passwords(resource)

      render :new
    end
  end
end
