class AuthenticationsController < ApplicationController
  load_and_authorize_resource :user

  load_and_authorize_resource :authentication, :through => :user

  def destroy
    @authentication.destroy

    redirect_to user_authentications_url(@user)
  end
end
