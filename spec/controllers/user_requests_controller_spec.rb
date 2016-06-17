require 'rails_helper'

RSpec.describe UserRequestsController, :type => :controller do
  let(:user) { create :user }

  let(:another_user) { create :user }

  let(:user_request) { create :user_request, :user => user }

  it { should route(:get, '/users/1/user_requests').to(:action => :index, :user_id => 1) }

  it { should route(:get, '/user_requests').to(:action => :index) }

  it { should route(:post, '/users/1/user_requests').to(:action => :create, :user_id => 1) }

  it { should route(:get, '/users/1/user_requests/new').to(:action => :new, :user_id => 1) }

  it { should route(:get, '/users/1/user_requests/1/edit').to(:action => :edit, :user_id => 1, :id => 1) }

  it { should route(:put, '/users/1/user_requests/1').to(:action => :update, :user_id => 1, :id => 1) }

  it { should route(:patch, '/users/1/user_requests/1').to(:action => :update, :user_id => 1, :id => 1) }

  it { should route(:delete, '/users/1/user_requests/1').to(:action => :destroy, :id => 1, :user_id => 1) }

  it { expect { get :new, :user_id => user }.to raise_error(CanCan::AccessDenied) }

  it { expect { get :edit, :id => user_request, :user_id => user }.to raise_error(CanCan::AccessDenied) }

  it do
    expect { post :create, :user_id => user, :user_request => { :foo => :bar } }.
      to raise_error(CanCan::AccessDenied)
  end

  it { expect { put :update, :user_id => user, :id => user_request }.to raise_error(CanCan::AccessDenied) }

  it { expect { patch :update, :user_id => user, :id => user_request }.to raise_error(CanCan::AccessDenied) }

  it { expect { delete :destroy, :id => user_request, :user_id => user }.to raise_error(CanCan::AccessDenied) }

  context 'User' do
    before { sign_in user }

    describe 'GET index with user_id' do
      before { get :index, :user_id => user }

      it { should redirect_to new_user_session_url(:locale => nil) }
    end

    describe 'GET index' do
      before { get :index }

      it { should redirect_to new_user_session_url(:locale => nil) }
    end

    describe 'GET edit' do
      before { get :edit, :user_id => user, :id => user_request }

      it { should redirect_to new_user_session_url(:locale => nil) }
    end

    describe 'GET new' do
      before { get :new, :user_id => user }

      it { should redirect_to new_user_session_url(:locale => nil) }
    end

    describe 'POST create' do
      before { post :create, :user_id => user }

      it { should redirect_to new_user_session_url(:locale => nil) }
    end

    describe 'PUT update' do
      before { put :update, :user_id => user, :id => user_request }

      it { should redirect_to new_user_session_url(:locale => nil) }
    end

    describe 'PATCH update' do
      before { patch :update, :user_id => user, :id => user_request }

      it { should redirect_to new_user_session_url(:locale => nil) }
    end

    describe 'DELETE destroy' do
      before { delete :destroy, :id => user_request, :user_id => user }

      it { should redirect_to new_user_session_url(:locale => nil) }
    end
  end

  context 'Confirmed user' do
    before { sign_in user; user.confirm }

    describe 'GET index with user_id' do
      before { get :index, :user_id => user }

      it { should render_template :index }
    end

    describe 'GET index' do
      before { get :index }

      it { should render_template :index }
    end

    describe 'GET edit' do
      before { get :edit, :user_id => user, :id => user_request }

      it { should render_template :edit }
    end

    describe 'GET new' do
      before { xhr :get, :new, :user_id => user }

      it { should render_template :new }
    end

    describe 'POST create' do
      context 'with valid params' do
        before do
          post :create, :user_id => user, :user_request => { :content => 'Some content' }
        end

        it { should redirect_to user_user_requests_url(assigns(:user)) }
      end

      context 'with invalid params' do
        before { post :create, :user_id => user, :user_request => { :content => '' } }

        it { should render_template :new }
      end
    end

    describe 'PUT update' do
      context 'with valid attributes' do
        before do
          put :update, :user_id => user, :id => user_request,
            :user_request => { :content => 'Some content' }
        end

        it { should redirect_to user_user_requests_url(assigns(:user)) }
      end

      context 'with invalid attributes' do
        before do
          put :update, :user_id => user, :id => user_request,
            :user_request => { :content => '' }
        end

        it { should render_template :edit }
      end
    end

    describe 'DELETE destroy' do
      before { delete :destroy, :id => user_request, :user_id => user }

      it { should redirect_to user_user_requests_url(assigns(:user)) }
    end
  end
end
