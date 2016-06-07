class IssuesController < ApplicationController
  load_and_authorize_resource :project

  load_and_authorize_resource :issue, :through => :project

  before_filter :assign_user, :only => [:create]

  def index
    if params[:column_id].present? || params[:section_id].present?
      @connections = @project.issue_to_section_connections.includes(:issue)

      @connections = @connections.where(:column_id => params[:column_id]) if params[:column_id].present?

      @connections = @connections.where(:section_id => params[:section_id]) if params[:section_id].present?

      @connections = @connections.page(params[:page])

      @issues = @connections.map(&:issue)
    else
      @issues = @project.issues.includes(:project).page(params[:page])
    end
  end

  def create
    if @issue.save
      redirect_to project_url(@issue.project), :turbolinks => true
    else
      render :new
    end
  end

  def update
    if @issue.update_attributes(issue_params)
      redirect_to project_url(@issue.project), :turbolinks => true
    else
      render :edit
    end
  end

  def destroy
    @issue.destroy

    redirect_to project_url(@issue.project)
  end

  private

  def issue_params
    params.require(:issue).permit(:title, :body, :tags => [])
  end

  def assign_user
    @issue.user_to_issue_connections.build(:user_id => current_user.id, :role => 'creator')
  end
end
