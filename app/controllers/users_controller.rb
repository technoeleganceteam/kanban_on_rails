# Controller for manage users
class UsersController < ApplicationController
  load_and_authorize_resource :except => [:index, :new, :create]

  before_action :find_and_check_manage, :only => [:new, :create]

  before_action :find_and_check_read, :only => [:index]

  before_action :build_user_and_connection, :only => [:create]

  def dashboard
  end

  def index
    @connections = @board.user_to_board_connections.includes(:user).
      order('created_at DESC').page(params[:page])
  end

  def new
    @user = @board.users.build
  end

  def create
    if @user.save
      redirect_to board_users_url(@board)
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
    @board = Board.find(params[:board_id])

    authorize! :manage, @board
  end

  def find_and_check_read
    @board = Board.find(params[:board_id])

    authorize! :read, @board
  end

  def build_user_and_connection
    @user = User.build_user(create_params)

    @user.password = create_params[:password] unless @user.persisted?

    build_connection
  end

  def build_connection
    board_id = @board.id

    connection = if @user.persisted?
      UserToBoardConnection.where(:user_id => @user.id, :board_id => board_id).first_or_initialize
    else
      @user.user_to_board_connections.build(:board_id => board_id)
    end

    connection.role = params[:role] if can? :manage, @board
  end
end
