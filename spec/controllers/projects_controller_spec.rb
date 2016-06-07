require 'rails_helper'

RSpec.describe ProjectsController, :type => :controller do
  let(:user) { create :user }

  let(:project) { create :project  }
  
  let(:issue) { create :issue, :project => project, :tags => ['foo', 'bar', 'tag'] }

  let(:connection) do
    create :user_to_project_connection, :user_id => user.id, :project_id => project.id, :role => 'owner'
  end

  let(:another_user) { create :user }

  it { should route(:get, '/users/1/projects/sync_with_github').to(:action => :sync_with_github, :user_id => 1) }

  it { should route(:get, '/users/1/projects/sync_with_bitbucket').
    to(:action => :sync_with_bitbucket, :user_id => 1) }

  it { should route(:get, '/users/1/projects').to(:action => :index, :user_id => 1) }

  it { should route(:get, '/projects/1').to(:action => :show, :id => 1) }

  it { should route(:post, '/users/1/projects').to(:action => :create, :user_id => 1) }

  it { should route(:post, '/projects/1/payload_from_github').to(:action => :payload_from_github, :id => 1) }

  it { should route(:post, '/projects/1/payload_from_bitbucket').to(:action => :payload_from_bitbucket, :id => 1) }

  it { should route(:get, '/users/1/projects/1/edit').to(:action => :edit, :id => 1, :user_id => 1) }

  it { should route(:patch, '/users/1/projects/1').to(:action => :update, :id => 1, :user_id => 1) }

  it { should route(:put, '/users/1/projects/1').to(:action => :update, :id => 1, :user_id => 1) }

  it { should route(:delete, '/users/1/projects/1').to(:action => :destroy, :id => 1, :user_id => 1) }

  it { expect { get :sync_with_github, :user_id => user }.to raise_error(CanCan::AccessDenied) }

  it { expect { get :sync_with_bitbucket, :user_id => user }.to raise_error(CanCan::AccessDenied) }

  it { expect { get :index, :user_id => user }.to raise_error(CanCan::AccessDenied) }
  
  it { expect { get :show, :id => project }.to raise_error(CanCan::AccessDenied) }

  it { expect { get :edit, :id => project, :user_id => user }.to raise_error(CanCan::AccessDenied) }

  it { expect { post :create, :user_id => user }.to raise_error(CanCan::AccessDenied) }
   
  it { expect { put :update, :user_id => user, :id => connection.project }.to raise_error(CanCan::AccessDenied) }

  it { expect { patch :update, :user_id => user, :id => connection.project }.to raise_error(CanCan::AccessDenied) }

  it { expect { delete :destroy, :user_id => user, :id => connection.project }.
    to raise_error(CanCan::AccessDenied) }

  describe 'POST payload_from_github' do
    context 'when nothing payload' do
      before { post :payload_from_github, :id => connection.project }

      it { expect(response.body).to be_blank }
    end

    context 'when some payload present' do
      before do
        allow(Rack::Utils).to receive(:secure_compare).and_return(true)

        post :payload_from_github, :id => connection.project
      end

      it { expect(response.body).to be_blank }
    end
  end

  describe 'POST payload_from_bitbucket' do
    context 'when nothing payload' do
      before { post :payload_from_bitbucket, :id => connection.project }

      it { expect(response.body).to be_blank }
    end

    context 'when some payload present' do

    end
  end

  context 'Confirmed user' do
    before { sign_in user; user.confirm }

    describe 'GET show' do
      before { get :show, :id => connection.project }

      it { should render_template :show }
    end

    describe 'GET sync_with_github' do
      before { xhr :get, :sync_with_github, :id => connection.project.id, :user_id => user, :format => :js }

      it do
        expect(response.body).to eq(
          "Turbolinks.visit('http://test.host/users/#{ user.id }/projects');"
        )
      end
    end

    describe 'GET sync_with_bitbucket' do
      before { xhr :get, :sync_with_bitbucket, :id => connection.project.id, :user_id => user, :format => :js }

      it do
        expect(response.body).to eq(
          "Turbolinks.visit('http://test.host/users/#{ user.id }/projects');"
        )
      end
    end

    describe 'GET stop_sync_with_github' do
      before { xhr :get, :stop_sync_with_github,
        :id => connection.project.id, :user_id => user, :format => :js }

      it do
        expect(response.body).to eq(
          "Turbolinks.visit('http://test.host/users/#{ user.id }/projects');"
        )
      end
    end

    describe 'GET stop_sync_with_bitbucket' do
      before { xhr :get, :stop_sync_with_bitbucket,
        :id => connection.project.id, :user_id => user, :format => :js }

      it do
        expect(response.body).to eq(
          "Turbolinks.visit('http://test.host/users/#{ user.id }/projects');"
        )
      end
    end

    describe 'GET edit' do
      before { get :edit, :id => connection.project.id, :user_id => user }

      it { should render_template :edit }
    end

    describe 'GET index' do
      before { get :index, :user_id => user }

      it { should render_template :index }
    end

    describe 'POST create' do
      context 'with valid attributes' do
        before { post :create, :user_id => user, :project => { :name => 'Some name' }, :format => :js }

        it do
          expect(response.body).to eq(
            "Turbolinks.visit('http://test.host/projects/#{ assigns(:project).id }');"
          )
        end
      end

      context 'with invalid attributes' do
        before { post :create, :user_id => user, :project => { :name => '' }, :format => :js }
          
        it { should render_template :new } 
      end
    end

    describe 'PATCH update as JS' do
      context 'with valid attributes' do
        before { put :update, :user_id => user, :id => connection.project,
          :project => { :name => 'Some name2' }, :format => :js }

        it do
          expect(response.body).to eq(
            "Turbolinks.visit('http://test.host/projects/#{ assigns(:project).id }');"
          )
        end
      end

      context 'with invalid attributes' do
        before { put :update, :user_id => user, :id => connection.project,
          :project => { :name => '' }, :format => :js }
          
        it { should render_template :edit } 
      end

      context 'with attributes for columns with overlapping tags' do
        before do
          put :update, :user_id => user, :id => connection.project,
            :project => { :name => 'Some name', :columns_attributes =>
              { '0' => { :name => 'Some name', :tags => ['bar'] },
                '1' => { :name => 'Some name', :tags => ['bar'] } } }, :format => :js
        end
          
        it { should render_template :edit }
      end

      context 'with attributes for issues_to_section_connection and section' do
        before do
          section = create :section, :project => project

          issue_connection = create :issue_to_section_connection, :issue => issue, :section => section

          put :update, :user_id => user, :id => connection.project,
            :project => { :name => 'Some name', :issues_to_section_connections_attributes =>
              { '0' => { :id => issue_connection.id, :issue_order => 1 } },
              :sections_attributes => { '0' => { :id => section.id, :name => 'Bar' } } }, :format => :js
        end
          
        it do
          expect(response.body).to eq(
            "Turbolinks.visit('http://test.host/projects/#{ assigns(:project).id }');"
          )
        end
      end

      context 'with attributes for issues' do
        before do
          put :update, :user_id => user, :id => connection.project,
            :project => { :name => 'Some name', :issues_attributes =>
              { '0' => { :id => issue.id, :tags => ['foo', 'bar'] } } }, :format => :js
        end
          
        it do
          expect(response.body).to eq(
            "Turbolinks.visit('http://test.host/projects/#{ assigns(:project).id }');"
          )
        end
      end

      context 'with attributes for issues and when issue connected to github' do
        before do
          issue.github_issue_id = 123
          
          issue.save

          put :update, :user_id => user, :id => connection.project,
            :project => { :name => 'Some name', :issues_attributes =>
              { '0' => { :id => issue.id, :tags => ['foo', 'bar'] } } }, :format => :js
        end
          
        it do
          expect(response.body).to eq(
            "Turbolinks.visit('http://test.host/projects/#{ assigns(:project).id }');"
          )
        end
      end

      context 'with attributes for issues when issue in multiple sections' do
        before do
          create :section, :tags => ['foo'], :project => project

          create :section, :tags => ['bar'], :project => project

          create :column, :tags => ['tag'], :project => project

          issue.save

          put :update, :user_id => user, :id => connection.project,
            :project => { :name => 'Some name', :issues_attributes =>
              { '0' => { :id => issue.id, :tags => ['foo', 'bar'] } } }, :format => :js
        end
          
        it do
          expect(response.body).to eq(
            "Turbolinks.visit('http://test.host/projects/#{ assigns(:project).id }');"
          )
        end
      end

      context 'with attributes for issues when issue in include all section' do
        before do
          create :section, :include_all => true, :project => project

          create :section, :tags => ['bar'], :project => project

          create :column, :tags => ['tag'], :project => project

          issue.save

          put :update, :user_id => user, :id => connection.project,
            :project => { :name => 'Some name', :issues_attributes =>
              { '0' => { :id => issue.id, :tags => ['foo', 'bar'] } } }, :format => :js
        end
          
        it do
          expect(response.body).to eq(
            "Turbolinks.visit('http://test.host/projects/#{ assigns(:project).id }');"
          )
        end
      end
    end

    describe 'DELETE destroy' do
      before { delete :destroy, :user_id => user, :id => connection.project }

      it { should redirect_to user_projects_url(assigns(:user)) }
    end
  end

  context 'Confirmed another user' do
    before { sign_in another_user; another_user.confirm }

    describe 'GET show project of first user' do
      it { expect { get :show, :id => connection.project }.to raise_error(CanCan::AccessDenied) }
    end

    describe 'GET edit project of first user' do
      it { expect { get :edit, :id => connection.project, :user_id => user }.to raise_error(CanCan::AccessDenied) }
    end

    describe 'GET index of user first projects' do
      it { expect { get :index, :user_id => user }.to raise_error(CanCan::AccessDenied) }
    end

    describe 'GET sync_with_github' do
      it { expect { xhr :get, :sync_with_github, :id => connection.project.id, :user_id => user, :format => :js }.
        to raise_error(CanCan::AccessDenied) }
    end

    describe 'GET sync_with_bitbucket' do
      it { expect { xhr :get, :sync_with_bitbucket, :id => connection.project.id,
        :user_id => user, :format => :js }.to raise_error(CanCan::AccessDenied) }
    end

    describe 'POST create project for first user' do
      it { expect { post :create, :user_id => user, :project => { :name => 'Some name' }, :format => :js }.
        to raise_error(CanCan::AccessDenied) }
    end

    describe 'PUT update project for first user' do
      it { expect { put :update, :user_id => user, :id => connection.project,
        :project => { :name => 'Some name2' }, :format => :js }.
        to raise_error(CanCan::AccessDenied) }
    end

    describe 'DELETE destroy' do
      it { expect { delete :destroy, :user_id => user, :id => connection.project }.
        to raise_error(CanCan::AccessDenied) }
    end
  end
end
