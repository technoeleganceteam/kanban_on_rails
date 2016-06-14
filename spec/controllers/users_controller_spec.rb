require 'rails_helper'

RSpec.describe UsersController, :type => :controller do
  let(:user) { create :user, :password => 'some1234' }

  let(:another_user) { create :user }

  let(:board) { create :board }

  it { should route(:get, '/projects/1/users').to(:action => :index, :project_id => 1) }
  
  it { should route(:get, '/users/1').to(:action => :show, :id => 1) }

  it { should route(:get, '/users/1/edit').to(:action => :edit, :id => 1) }

  it { should route(:post, '/boards/1/users').to(:action => :create, :board_id => 1) }

  it { should route(:get, '/boards/1/users/new').to(:action => :new, :board_id => 1) }

  it { should route(:patch, '/users/1').to(:action => :update, :id => 1) }

  it { should route(:put, '/users/1').to(:action => :update, :id => 1) }

  it { expect { get :show, :id => user }.to raise_error(CanCan::AccessDenied) }

  it { expect { get :edit, :id => user }.to raise_error(CanCan::AccessDenied) }

  it { expect { get :dashboard, :id => user }.to raise_error(CanCan::AccessDenied) }

  it { expect { put :update, :id => user }.to raise_error(CanCan::AccessDenied) }

  it { expect { patch :update, :id => user }.to raise_error(CanCan::AccessDenied) }

  context 'User' do
    before { sign_in user }

    describe 'GET show' do
      before { get :show, :id => user }

      it { should redirect_to new_user_session_url(:locale => nil) }
    end

    describe 'GET dashboard' do
      before { get :dashboard, :id => user }

      it { should redirect_to new_user_session_url(:locale => nil) }
    end

    describe 'GET edit' do
      before { get :edit, :id => user }

      it { should redirect_to new_user_session_url(:locale => nil) }
    end
  end

  context 'Confirmed user' do
    before { sign_in user; user.confirm }

    describe 'GET show' do
      before { get :show, :id => user }

      it { should render_template :show }

      it { expect(assigns(:user)).not_to be_nil }
    end

    describe 'GET dashboard' do
      before { get :dashboard, :id => user }

      it { should render_template :dashboard }

      it { expect(assigns(:user)).not_to be_nil }
    end

    describe 'GET edit' do
      before { get :edit, :id => user }

      it { should render_template :edit }

      it { expect(assigns(:user)).not_to be_nil }
    end

    describe 'GET new' do
      before do
        connection = user.user_to_board_connections.create :board => board, :role => 'owner'

        get :new, :board_id => connection.board
      end

      it { should render_template :new }
    end

    describe 'GET index' do
      before do
        connection = user.user_to_board_connections.create :board => board, :role => 'owner'

        get :index, :board_id => connection.board
      end

      it { should render_template :index }
    end

    describe 'POST create' do
      context 'with invalid attributes' do
        before do
          connection = user.user_to_board_connections.create :board => board, :role => 'owner'

          post :create, :board_id => connection.board, :user => { :name => '' }
        end

        it { should render_template :new }
      end

      context 'with valid attributes' do
        before do
          connection = user.user_to_board_connections.create :board => board, :role => 'owner'

          post :create, :board_id => connection.board,
            :user => { :name => 'Name', :password => '12345678', :email => 'some@mail.com' }, :role => 'owner'
        end

        it { should redirect_to board_users_url(board) }
      end

      context 'with valid attributes when user with email already exists' do
        before do
          connection = user.user_to_board_connections.create :board => board, :role => 'owner'

          create :user, :email => 'some@mail.com'

          post :create, :board_id => connection.board,
            :user => { :name => 'Name', :password => '12345678', :email => 'some@mail.com' }, :role => 'owner'
        end

        it { should redirect_to board_users_url(board) }
      end
    end

    describe 'PATCH update as JS' do
      context 'with valid attributes' do
        before { put :update, :id => user, :user => { :email => 'some@email.com' }, :format => :js }

        it { assigns(:user).email == 'some@email.com' }

        it { should render_template :update }
      end

      context 'with invalid attributes' do
        before { patch :update, :id => user, :user => { :email => '' }, :format => :js }

        it { should render_template :update }
      end

      context 'with password present but empty' do
        before do
          patch :update, :id => user, :user => { :email => '', :password => '', :current_password => '' },
            :format => :js
        end

        it { expect(assigns(:user).errors.messages[:password].first).to eq "can't be blank" }

        it { should render_template :update }
      end

      context 'with password present but not empty' do
        before do
          patch :update, :id => user,
            :user => { :email => '', :password => 'some12345', :current_password => 'some1234' }, :format => :js
        end

        it { should render_template :update }
      end
    end
  end

  context 'Confirmed another user' do
    before { sign_in another_user; another_user.confirm }

    describe 'GET dashboard of first user' do
      it { expect { get :show, :id => user }.to raise_error(CanCan::AccessDenied) }
    end

    describe 'GET dashboard of first user' do
      it { expect { get :dashboard, :id => user }.to raise_error(CanCan::AccessDenied) }
    end
  end
end
