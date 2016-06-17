class UserRequestsController < ApplicationController
  load_and_authorize_resource :user, :except => [:index]

  load_and_authorize_resource :user_request, :through => :user, :except => [:index, :popular]

  before_action :find_user, :only => [:index]

  def index
    @user_requests = if @user.present?
      @user.user_requests.page(params[:page])
    else
      UserRequest.order('created_at DESC').includes(:user).page(params[:page])
    end
  end

  def create
    if @user_request.save
      redirect_to user_user_requests_url(@user)
    else
      render :new
    end
  end

  def update
    if @user_request.update_attributes(user_request_params)
      redirect_to user_user_requests_url(@user)
    else
      render :edit
    end
  end

  def destroy
    @user_request.destroy

    redirect_to user_user_requests_url(@user)
  end

  private

  def user_request_params
    params.require(:user_request).permit(:content)
  end

  def find_user
    @user = User.find(params[:user_id]) if params[:user_id].present?
  end
end
