class IssuesController < ApplicationController
  load_and_authorize_resource :project

  load_and_authorize_resource :issue, :through => :project, :shallow => true

  before_filter :assign_user, :only => [:create]

  def index
    if (params[:column_id].present? || params[:section_id].present?) && params[:board_id].present?
      @board = Board.find(params[:board_id])

      @connections = @board.issue_to_section_connections.includes(:issue => :project)

      @connections = @connections.where(:column_id => params[:column_id]) if params[:column_id].present?

      @connections = @connections.where(:section_id => params[:section_id]) if params[:section_id].present?

      @connections = @connections.page(params[:page])

      @issues = @connections.map(&:issue)
    elsif params[:project_id].present?
      @issues = @project.issues.includes(:project).page(params[:page])
    else
      @issues = current_user.issues.includes(:project).page(params[:page])
    end
  end

  def create
    if @issue.save
      enqueue_issue_sync

      redirect_to project_url(@issue.project), :turbolinks => !request.format.html?
    else
      render :new
    end
  end

  def update
    if @issue.update_attributes(update_params)
      enqueue_issue_sync

      redirect_to project_url(@issue.project), :turbolinks => !request.format.html?
    else
      render :edit
    end
  end

  def destroy
    @issue.destroy

    redirect_to project_url(@issue.project)
  end

  private

  def create_params
    params.require(:issue).permit(:title, :body, :project_id, :tags => [])
  end

  def update_params
    params.require(:issue).permit(:title, :body, :tags => [])
  end

  def assign_user
    @issue.user_to_issue_connections.build(:user_id => current_user.id, :role => 'creator')
  end

  def enqueue_issue_sync
    Issue.user_change_issue(@issue.id, current_user.id)
  end
end
