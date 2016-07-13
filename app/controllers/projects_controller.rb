class ProjectsController < ApplicationController
  load_and_authorize_resource :user, :except => [:payload_from_bitbucket,
    :payload_from_github, :payload_from_gitlab]

  load_resource :project, :through => :user, :shallow => true

  authorize_resource :project, :through => :user, :shallow => true,
    :except => [:payload_from_github, :payload_from_bitbucket, :payload_from_gitlab]

  before_action :assign_owner, :only => [:create]

  skip_before_action :verify_authenticity_token, :only => [:payload_from_github,
    :payload_from_bitbucket, :payload_from_gitlab]

  def index
    @projects = @user.projects_from_search(params[:q]).page(params[:page])

    respond_to do |format|
      format.html

      format.json { render :json => projects_for_json }
    end
  end

  Settings.issues_providers.each do |provider|
    define_method "sync_with_#{ provider }" do
      current_user.update_attribute("sync_with_#{ provider }", true)

      "sync_#{ provider }_worker".classify.constantize.perform_async(@user.id)

      render :start_sync_with_provider
    end

    define_method "stop_sync_with_#{ provider }" do
      current_user.update_attribute("sync_with_#{ provider }", false)

      redirect_to user_projects_url(@user), :turbolinks => true
    end
  end

  def payload_from_github
    unless Rack::Utils.secure_compare(signature_from_payload, request.env['HTTP_X_HUB_SIGNATURE'].to_s)
      (render :status => 422, :nothing => true) && return
    end

    @project.parse_params_from_github_webhook(params)

    (render :status => 200, :nothing => true) && return
  end

  def payload_from_bitbucket
    if params[:secure_token] == @project.bitbucket_secret_token_for_hook
      @project.parse_params_from_bitbucket_webhook(params)
    end

    render :status => 200, :nothing => true
  end

  def payload_from_gitlab
    if params[:secure_token] == @project.gitlab_secret_token_for_hook
      @project.parse_params_from_gitlab_webhook(params)
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
    params.require(:project).permit(:name, :include_issues, :include_pull_requests, :changelog_locale,
      :generate_changelogs, :close_issues, :write_changelog_to_repository, :changelog_filename,
      :include_detailed_changes, :emails_for_reports => [])
  end

  def assign_owner
    @project.user_to_project_connections.build(:user_id => @user.id, :role => 'owner')
  end

  def signature_from_payload
    request.body.rewind

    payload_body = request.body.read

    'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'),
      @project.github_secret_token_for_hook.to_s, payload_body)
  end

  def projects_for_json
    {
      :results => @projects.map { |p| { :id => p.id, :text => p.name } },
      :total_count => @projects.total_count
    }
  end
end
