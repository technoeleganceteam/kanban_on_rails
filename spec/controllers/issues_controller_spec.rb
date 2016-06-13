require 'rails_helper'

RSpec.describe IssuesController, :type => :controller do
  let(:user) { create :user }

  let(:project) { create :project  }
  
  let(:issue) { create :issue, :project => project, :tags => ['foo', 'bar', 'tag'] }

  let(:connection) do
    create :user_to_project_connection, :user_id => user.id, :project_id => project.id, :role => 'owner'
  end

  let(:another_user) { create :user }

  it { should route(:get, '/projects/1/issues').to(:action => :index, :project_id => 1) }

  it { should route(:post, '/projects/1/issues').to(:action => :create, :project_id => 1) }

  it { should route(:patch, '/projects/1/issues/1').to(:action => :update, :id => 1, :project_id => 1) }

  it { should route(:put, '/projects/1/issues/1').to(:action => :update, :id => 1, :project_id => 1) }

  it { should route(:delete, '/projects/1/issues/1').to(:action => :destroy, :id => 1, :project_id => 1) }

  it { expect { get :index, :project_id => project }.to raise_error(CanCan::AccessDenied) }
  
  it { expect { post :create, :project_id => project }.to raise_error(CanCan::AccessDenied) }
   
  it { expect { put :update, :project_id => project, :id => issue }.to raise_error(CanCan::AccessDenied) }

  it { expect { patch :update, :project_id => project, :id => issue }.to raise_error(CanCan::AccessDenied) }

  it { expect { delete :destroy, :project_id => project, :id => issue }.
    to raise_error(CanCan::AccessDenied) }

  context 'Confirmed user' do
    before { sign_in user; user.confirm }

    describe 'GET index' do
      context 'without any sections or columns' do
        before { xhr :get, :index, :project_id => connection.project, :format => :js }

        it { should render_template :index }
      end

      context 'without any sections or columns' do
        before do
          connection.project.boards << (create :board)
          
          connection.save
          
          xhr :get, :index, :project_id => connection.project, :board_id => connection.project.boards.first.id,
          :column_id => 1, :section_id => 1, :format => :js
        end

        it { should render_template :index }
      end

      context 'without project_id' do
        before { xhr :get, :index, :user_id => user }

        it { should render_template :index }
      end
    end

    describe 'POST create' do
      context 'with valid attributes' do
        before { post :create, :project_id => connection.project,
          :issue => { :title => 'Some title' }, :format => :js }

        it do
          expect(response.body).to eq(
            "Turbolinks.visit('http://test.host/projects/#{ assigns(:project).id }');"
          )
        end
      end

      context 'with invalid attributes' do
        before { post :create, :project_id => connection.project, :issue => { :title => '' }, :format => :js }
          
        it { should render_template :new } 
      end

      context 'with overlapping tags to some sections' do
        before do
          board = create :board

          connection.project.boards << board
          
          connection.save

          create :section, :board => board, :include_all => true

          create :section, :board => board, :tags => ['foo']

          create :column, :board => board, :tags => ['foo']
          
          post :create, :project_id => connection.project,
          :issue => { :title => 'Some title', :tags => ['foo'] }, :format => :js
        end

        it do
          expect(response.body).to eq(
            "Turbolinks.visit('http://test.host/projects/#{ assigns(:project).id }');"
          )
        end
      end
    end

    describe 'PATCH update as JS' do
      context 'with valid attributes' do
        before { put :update, :project_id => connection.project, :id => issue,
          :issue => { :title => 'Some title2' }, :format => :js }

        it do
          expect(response.body).to eq(
            "Turbolinks.visit('http://test.host/projects/#{ assigns(:project).id }');"
          )
        end
      end

      context 'with invalid attributes' do
        before { put :update, :project_id => connection.project, :id => issue,
          :issue => { :title => '' }, :format => :js }
          
        it { should render_template :edit } 
      end
    end

    describe 'DELETE destroy' do
      before { delete :destroy, :project_id => connection.project, :id => issue }

      it { should redirect_to project_url(assigns(:issue).project) }
    end
  end

  context 'Confirmed another user' do
    before { sign_in another_user; another_user.confirm }

    describe 'GET index of user first project issues' do
      it { expect { get :index, :project_id => project }.to raise_error(CanCan::AccessDenied) }
    end

    describe 'POST create issue for first user project' do
      it { expect { post :create, :issue => { :title => 'Some title' }, :project_id => project, :format => :js }.
        to raise_error(CanCan::AccessDenied) }
    end

    describe 'PUT update issue for first user project' do
      it { expect { put :update, :project_id => project, :id => issue,
        :issue => { :title => 'Some title2' }, :format => :js }.
        to raise_error(CanCan::AccessDenied) }
    end

    describe 'DELETE destroy' do
      it { expect { delete :destroy, :project_id => project, :id => connection.project }.
        to raise_error(CanCan::AccessDenied) }
    end
  end
end
