class BoardsController < ApplicationController
  load_and_authorize_resource :user

  load_resource :board, :through => :user, :shallow => true

  authorize_resource :board, :through => :user, :shallow => true

  before_action :assign_owner, :only => [:create]

  before_action :handle_issues_attributes, :only => [:update]

  def new
  end

  def index
    @boards = @user.boards.order('created_at DESC').page(params[:page])
  end

  def show
    @sections = @board.sections.order('section_order ASC')

    @columns = @board.columns.order('column_order ASC')

    @columns_count = @board.columns.size
  end

  def create
    if @board.save
      redirect_to board_url(@board), :turbolinks => !request.format.html?
    else
      render :new
    end
  end

  def update
    if @board.update_attributes(board_params)
      enqueue_issue_sync if board_params[:issues_attributes].present?

      redirect_to board_url(@board), :turbolinks => !request.format.html?
    else
      render :edit
    end
  end

  def destroy
    @board.destroy

    redirect_to user_boards_url(@user)
  end

  private

  def board_params
    params.require(:board).permit(:name, :column_width, :column_height, :project_ids => [],
      :issue_to_section_connections_attributes => [:id, :issue_order, :column_id],
      :columns_attributes => [:name, :max_issues_count, :tags, :id, :_destroy, :column_order, :tags => []],
      :sections_attributes => [:name, :id, :tags, :_destroy, :section_order, :include_all, :tags => []],
      :issues_attributes => [:id, :tags => []])
  end

  def assign_owner
    @board.user_to_board_connections.build(:user_id => @user.id, :role => 'owner')
  end

  def handle_issues_attributes
    return unless board_params[:issues_attributes].present?

    params[:board][:issues_attributes] = params[:board][:issues_attributes].map do |attributes|
      issue = Issue.find(attributes.last[:id])

      issue.parse_attributes_for_update(attributes.last)
    end
  end

  def enqueue_issue_sync
    return unless board_params[:issues_attributes].present?

    board_params[:issues_attributes].each { |attr| Issue.user_change_issue(attr[:id], current_user.id) }
  end
end
