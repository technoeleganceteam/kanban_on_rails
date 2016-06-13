class ProjectsController < ApplicationController
  load_and_authorize_resource :user, :except => [:payload_from_bitbucket,
    :payload_from_github, :payload_from_gitlab]

  load_resource :project, :through => :user, :shallow => true

  authorize_resource :project, :through => :user, :shallow => true,
    :except => [:payload_from_github, :payload_from_bitbucket, :payload_from_gitlab]

  before_filter :assign_owner, :only => [:create]

  skip_before_filter :verify_authenticity_token, :only => [:payload_from_github,
    :payload_from_bitbucket, :payload_from_gitlab]

  def index
    @projects = @user.projects.order('created_at DESC')

    @projects = @projects.where('name ilike ?', "%#{ params[:q] }%") if params[:q].present?

    @projects = @projects.page(params[:page])

    respond_to do |format|
      format.html

      format.json { render :json => {
        :results => @projects.map { |p| { :id => p.id, :text => p.name } },
        :total_count => @projects.total_count } }
    end
  end

  def sync_with_github
    current_user.update_attribute(:sync_with_github, true)

    SyncGithubWorker.perform_async(@user.id)

    redirect_to user_projects_url(@user), :turbolinks => true
  end

  def sync_with_gitlab
    current_user.update_attribute(:sync_with_gitlab, true)

    SyncGitlabWorker.perform_async(@user.id)

    redirect_to user_projects_url(@user), :turbolinks => true
  end

  def sync_with_bitbucket
    current_user.update_attribute(:sync_with_bitbucket, true)
    
    SyncBitbucketWorker.perform_async(@user.id)

    redirect_to user_projects_url(@user), :turbolinks => true
  end

  def stop_sync_with_github
    current_user.update_attribute(:sync_with_github, false)

    redirect_to user_projects_url(@user), :turbolinks => true
  end

  def stop_sync_with_gitlab
    current_user.update_attribute(:sync_with_gitlab, false)

    redirect_to user_projects_url(@user), :turbolinks => true
  end

  def stop_sync_with_bitbucket
    current_user.update_attribute(:sync_with_bitbucket, false)

    redirect_to user_projects_url(@user), :turbolinks => true
  end

  def payload_from_github
    request.body.rewind

    payload_body = request.body.read

    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'),
      @project.github_secret_token_for_hook.to_s, payload_body)

    unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'].to_s)
      (render :status => 422, :nothing => true) and return
    end

    @project.parse_issue_params_from_github_webhook(params[:issue]) if params[:issue].present?

    (render :status => 200, :nothing => true) and return
  end

  def payload_from_bitbucket
    if params[:secure_token] == @project.bitbucket_secret_token_for_hook
      @project.parse_issue_params_from_bitbucket_webhook(params[:issue]) if params[:issue].present?
    end

    render :status => 200, :nothing => true
  end

  def payload_from_gitlab
    if params[:secure_token] == @project.gitlab_secret_token_for_hook
      if params[:object_attributes].present?
        @project.parse_issue_params_from_gitlab_webhook(params[:object_attributes]) 
      end
    end

    render :status => 200, :nothing => true
  end

  def show
    @boards = @project.boards.order('created_at DESC').page(params[:page])
  end

  def create
    if @project.save
      redirect_to project_url(@project), :turbolinks => !request.format.html?
    else
      render :new
    end
  end

  def update
    if @project.update_attributes(project_params)
      redirect_to project_url(@project), :turbolinks => !request.format.html?
    else
      render :edit
    end
  end

  def destroy
    @project.destroy

    redirect_to user_projects_url(@user)
  end

  private

  def project_params
    params.require(:project).permit(:name)
  end

  def assign_owner
    @project.user_to_project_connections.build(:user_id => @user.id, :role => 'owner')
  end
end
