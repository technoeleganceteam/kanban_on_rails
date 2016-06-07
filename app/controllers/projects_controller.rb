class ProjectsController < ApplicationController
  load_and_authorize_resource :user, :except => [:payload_from_bitbucket, :payload_from_github]

  load_resource :project, :through => :user, :shallow => true

  authorize_resource :project, :through => :user, :shallow => true,
    :except => [:payload_from_github, :payload_from_bitbucket]

  before_filter :handle_issues_attributes, :only => [:update]

  before_filter :assign_owner, :only => [:create]

  skip_before_filter :verify_authenticity_token, :only => [:payload_from_github, :payload_from_bitbucket]

  def index
    @projects = @user.projects.order('created_at DESC').page(params[:page])
  end

  def sync_with_github
    current_user.update_attribute(:sync_with_github, true)

    SyncGithubWorker.perform_async(@user.id)

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

  def show
    @sections = @project.sections.order('section_order ASC') 

    @columns = @project.columns.order('column_order ASC')

    @columns_count = @project.columns.size
  end

  def create
    if @project.save
      redirect_to project_url(@project), :turbolinks => true
    else
      render :new
    end
  end

  def update
    if @project.update_attributes(project_params)
      enqueue_issue_sync if project_params[:issues_attributes].present?

      redirect_to project_url(@project), :turbolinks => true
    else
      render :edit
    end
  end

  def destroy
    @project.destroy

    redirect_to user_projects_url(@user)
  end

  private

  def handle_issues_attributes
    return if !project_params[:issues_attributes].present?

    params[:project][:issues_attributes] = params[:project][:issues_attributes].map do |attributes|
      issue = Issue.find(attributes.last[:id])

      add_connection_attributes(issue, attributes) if issue.issue_to_section_connections.size > 1

      issue.parse_attributes_for_update(attributes.last)
    end
  end

  def project_params
    params.require(:project).permit(:name, :column_width, :column_height,
      :issue_to_section_connections_attributes => [:id, :issue_order, :column_id],
      :columns_attributes => [:name, :max_issues_count, :tags, :id, :_destroy, :column_order, :tags => []],
      :sections_attributes => [:name, :id, :tags, :_destroy, :section_order, :include_all, :tags => []],
      :issues_attributes => [:id, :tags => []])
  end

  def enqueue_issue_sync
    return unless project_params[:issues_attributes].present?

    project_params[:issues_attributes].each { |attr| Issue.user_change_issue(attr[:id], current_user.id) }
  end

  def add_connection_attributes(issue, attributes)
    issue.issue_to_section_connections.includes(:column).each do |connection|
      next if attributes.last[:target_column_id] == connection.column.id

      params[:project][:issue_to_section_connections_attributes] ||= {}

      key = params[:project][:issue_to_section_connections_attributes].keys.last.to_i + 1

      params[:project][:issue_to_section_connections_attributes][key.to_s] = {
        :id => connection.id, :issue_order => connection.column.max_order(connection.section),
        :column_id => attributes.last[:target_column_id]
      }
    end
  end

  def assign_owner
    @project.user_to_project_connections.build(:user_id => @user.id, :role => 'owner')
  end
end
