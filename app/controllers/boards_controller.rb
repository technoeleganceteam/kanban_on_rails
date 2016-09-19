# Controller for handle boards
class BoardsController < ApplicationController
  include Creatable

  load_and_authorize_resource :user

  load_resource :board, :through => :user, :shallow => true

  authorize_resource :board, :through => :user, :shallow => true

  before_action :assign_owner, :only => [:create]

  before_action :handle_issues_attributes, :only => [:update]

  def new
    @board = Board.new

    @board.columns << Column.new(:name => I18n.t('backlog'), :backlog => true, :tags => [])

    @board.sections << Section.new(:name => I18n.t('include_all'), :include_all => true, :tags => [])
  end

  def index
    @boards = @user.boards.order('created_at DESC').page(params[:page])
  end

  def show
    @board = @board.decorate
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
      :columns_attributes => [:name, :max_issues_count, :tags, :id,
        :_destroy, :column_order, :backlog, :tags => []],
      :sections_attributes => [:name, :id, :tags, :_destroy, :section_order, :include_all, :tags => []],
      :issues_attributes => [:id, :tags => []])
  end

  def assign_owner
    @board.user_to_board_connections.build(:user_id => @user.id, :role => 'owner')
  end

  def handle_issues_attributes
    return unless (issues_attributes = params[:board][:issues_attributes]).present?

    add_issue_attributes(issues_attributes)
  end

  def add_issue_attributes(issues_attributes)
    params[:board][:issues_attributes] = issues_attributes.map do |attributes|
      last_attribute = attributes.last

      issue = Issue.find(last_attribute[:id])

      IssueUtilities.parse_attributes_for_update(last_attribute, issue)
    end
  end

  def enqueue_issue_sync
    issues_attributes = board_params[:issues_attributes]

    return unless issues_attributes.present?

    issues_attributes.each { |attr| Issue.user_change_issue(attr[:id], current_user.id) }
  end
end
