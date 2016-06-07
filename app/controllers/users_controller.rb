class UsersController < ApplicationController
  load_and_authorize_resource :except => [:index, :new, :create]

  before_filter :find_and_check_manage, :only => [:new, :create]

  before_filter :find_and_check_read, :only => [:index]

  before_filter :find_existing_user, :only => [:create]

  def dashboard
    @projects_count = @user.projects.size

    @issues_count = @user.issues.size
  end

  def index
    @connections = @project.user_to_project_connections.includes(:user).
      order('created_at DESC').page(params[:page])
  end

  def new
    @user = @project.users.build
  end

  def create
    if @user.save
      redirect_to project_users_url(@project) 
    else
      render :new
    end
  end
  
  def edit
  end

  def update
    if update_params.key?(:password) && update_params.key?(:current_password)
      if update_params[:password].present?
        sign_in @user, :bypass => true if @user.update_with_password(update_params)
      else
        @user.errors.add(:password, :blank)
      end
    else
      @user.update_without_password(update_params)
    end
  end

  private

  def create_params
    params.require(:user).permit(:name, :locale, :email, :password)
  end

  def update_params
    params.require(:user).permit(:name, :current_password, :password, :password_confirmation, :locale)
  end

  def find_and_check_manage
    @project = Project.find(params[:project_id])

    authorize! :manage, @project
  end

  def find_and_check_read
    @project = Project.find(params[:project_id])

    authorize! :read, @project
  end

  def find_existing_user
    @user = User.where(:email => create_params[:email]).first_or_initialize

    @user.name ||= create_params[:name]

    @user.locale ||= create_params[:locale]

    if @user.persisted?
      connection = UserToProjectConnection.where(:user_id => @user.id, :project_id => @project.id).
        first_or_initialize
    else
      connection = @user.user_to_project_connections.
        build(:project_id => @project.id)

      @user.password = create_params[:password] 
    end

    connection.role = params[:role]
  end
end
