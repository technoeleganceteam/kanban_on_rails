# Controller for manage issues
class IssuesController < ApplicationController
  load_and_authorize_resource :project

  load_and_authorize_resource :issue, :through => :project, :shallow => true

  before_action :assign_user, :only => [:create]

  before_action :fetch_board_and_connections, :only => [:index]

  def index
    @issues = if @board.present? && @connections.present?
      @connections.map(&:issue)
    else
      (@project.present? ? @project.issues : current_user.issues.includes(:project)).page(params[:page])
    end
  end

  def create
    if @issue.save
      after_create_or_update
    else
      render :new
    end
  end

  def update
    if @issue.update_attributes(update_params)
      after_create_or_update
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
    params.require(:issue).permit(:title, :body, :state, :tags => [])
  end

  def assign_user
    @issue.user_to_issue_connections.build(:user_id => current_user.id, :role => 'creator')
  end

  def enqueue_issue_sync
    Issue.user_change_issue(@issue.id, current_user.id)
  end

  def fetch_board_and_connections
    board_id = params[:board_id]

    return unless board_id.present?

    @board = Board.find(board_id)

    @connections = @board.issue_to_section_connections_from_params(params).page(params[:page])
  end

  def after_create_or_update
    enqueue_issue_sync

    respond_after_create_or_update
  end

  def respond_after_create_or_update
    respond_to do |format|
      format.js { render :handle_save }

      format.html { redirect_to project_url(@issue.project) }
    end
  end
end
