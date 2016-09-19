require 'rails_helper'

RSpec.describe ProjectsController, :type => :controller do
  let(:user) { create :user }

  let(:project) { create :project }

  let(:issue) { create :issue, :project => project, :tags => %w(foo bar tag) }

  let(:connection) do
    create :user_to_project_connection, :user_id => user.id, :project_id => project.id, :role => 'owner'
  end

  let(:another_user) { create :user }

  it do
    should route(:get, '/users/1/projects/sync_from_github').to(:action => :sync_from_github, :user_id => 1)
  end

  it do
    should route(:get, '/users/1/projects/sync_from_gitlab').to(:action => :sync_from_gitlab, :user_id => 1)
  end

  it do
    should route(:get, '/users/1/projects/sync_from_bitbucket').to(:action => :sync_from_bitbucket, :user_id => 1)
  end

  it { should route(:get, '/users/1/projects').to(:action => :index, :user_id => 1) }

  it { should route(:get, '/projects/1').to(:action => :show, :id => 1) }

  it { should route(:post, '/users/1/projects').to(:action => :create, :user_id => 1) }

  it { should route(:post, '/projects/1/payload_from_github').to(:action => :payload_from_github, :id => 1) }

  it { should route(:post, '/projects/1/payload_from_bitbucket').to(:action => :payload_from_bitbucket, :id => 1) }

  it { should route(:post, '/projects/1/payload_from_gitlab').to(:action => :payload_from_gitlab, :id => 1) }

  it { should route(:get, '/users/1/projects/1/edit').to(:action => :edit, :id => 1, :user_id => 1) }

  it { should route(:patch, '/users/1/projects/1').to(:action => :update, :id => 1, :user_id => 1) }

  it { should route(:put, '/users/1/projects/1').to(:action => :update, :id => 1, :user_id => 1) }

  it { should route(:delete, '/users/1/projects/1').to(:action => :destroy, :id => 1, :user_id => 1) }

  it { expect { get :sync_from_github, :user_id => user }.to raise_error(CanCan::AccessDenied) }

  it { expect { get :sync_from_gitlab, :user_id => user }.to raise_error(CanCan::AccessDenied) }

  it { expect { get :sync_from_bitbucket, :user_id => user }.to raise_error(CanCan::AccessDenied) }

  it { expect { get :index, :user_id => user }.to raise_error(CanCan::AccessDenied) }

  it { expect { get :show, :id => project }.to raise_error(CanCan::AccessDenied) }

  it { expect { get :edit, :id => project, :user_id => user }.to raise_error(CanCan::AccessDenied) }

  it { expect { post :create, :user_id => user }.to raise_error(CanCan::AccessDenied) }

  it { expect { put :update, :user_id => user, :id => connection.project }.to raise_error(CanCan::AccessDenied) }

  it { expect { patch :update, :user_id => user, :id => connection.project }.to raise_error(CanCan::AccessDenied) }

  it do
    expect { delete :destroy, :user_id => user, :id => connection.project }.
      to raise_error(CanCan::AccessDenied)
  end

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
      before do
        post :payload_from_bitbucket, :id => connection.project,
          :issue => { :title => 'bar', :content => { :raw => 'foo' } }
      end

      it { expect(response.body).to be_blank }
    end

    context 'when push tag' do
      before do
        post :payload_from_bitbucket, :id => connection.project,
          :push => { :changes => [:new => { :type => 'tag' }] }
      end

      it { expect(response.body).to be_blank }
    end
  end

  describe 'POST payload_from_gitlab' do
    before do
      post :payload_from_gitlab, :id => connection.project,
      :object_attributes => { :title => 'bar' }
    end

    it { expect(response.body).to be_blank }
  end

  context 'Confirmed user' do
    before { sign_in user; user.confirm }

    describe 'GET show' do
      before { get :show, :id => connection.project }

      it { should render_template :show }
    end

    describe 'GET sync_from_github' do
      before { xhr :get, :sync_from_github, :id => connection.project.id, :user_id => user, :format => :js }

      it { should render_template :start_sync_with_provider }
    end

    describe 'GET sync_from_gitlab' do
      before { xhr :get, :sync_from_gitlab, :id => connection.project.id, :user_id => user, :format => :js }

      it { should render_template :start_sync_with_provider }
    end

    describe 'GET sync_from_bitbucket' do
      before { xhr :get, :sync_from_bitbucket, :id => connection.project.id, :user_id => user, :format => :js }

      it { should render_template :start_sync_with_provider }
    end

    describe 'GET stop_sync_with_github' do
      before do
        xhr :get, :stop_sync_with_github,
          :id => connection.project.id, :user_id => user, :format => :js
      end

      it do
        expect(response.body).to eq(
          "Turbolinks.visit('http://test.host/users/#{ user.id }/projects');"
        )
      end
    end

    describe 'GET stop_sync_with_gitlab' do
      before do
        xhr :get, :stop_sync_with_gitlab,
          :id => connection.project.id, :user_id => user, :format => :js
      end

      it do
        expect(response.body).to eq(
          "Turbolinks.visit('http://test.host/users/#{ user.id }/projects');"
        )
      end
    end

    describe 'GET stop_sync_with_bitbucket' do
      before do
        xhr :get, :stop_sync_with_bitbucket,
          :id => connection.project.id, :user_id => user, :format => :js
      end

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

    describe 'GET index JSON' do
      before do
        user.user_to_project_connections.create :role => 'owner', :project => (@project = create :project)

        get :index, :user_id => user, :format => :json
      end

      it do
        expect(response.body).to eq Hash[:results, [{ :id => @project.id, :text => 'Some project' }],
          :total_count, 1].to_json.to_s
      end
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
        before do
          put :update, :user_id => user, :id => connection.project,
          :project => { :name => 'Some name2' }, :format => :js
        end

        it do
          expect(response.body).to eq(
            "Turbolinks.visit('http://test.host/projects/#{ assigns(:project).id }');"
          )
        end
      end

      context 'with invalid attributes' do
        before do
          put :update, :user_id => user, :id => connection.project,
          :project => { :name => '' }, :format => :js
        end

        it { should render_template :edit }
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

    describe 'GET sync_from_github' do
      it do
        expect { xhr :get, :sync_from_github, :id => connection.project.id, :user_id => user, :format => :js }.
          to raise_error(CanCan::AccessDenied)
      end
    end

    describe 'GET sync_from_gitlab' do
      it do
        expect { xhr :get, :sync_from_gitlab, :id => connection.project.id, :user_id => user, :format => :js }.
          to raise_error(CanCan::AccessDenied)
      end
    end

    describe 'GET sync_from_bitbucket' do
      it do
        expect do
          xhr :get, :sync_from_bitbucket, :id => connection.project.id, :user_id => user, :format => :js
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    describe 'POST create project for first user' do
      it do
        expect { post :create, :user_id => user, :project => { :name => 'Some name' }, :format => :js }.
          to raise_error(CanCan::AccessDenied)
      end
    end

    describe 'PUT update project for first user' do
      it do
        expect do
          put :update, :user_id => user, :id => connection.project,
            :project => { :name => 'Some name2' }, :format => :js
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    describe 'DELETE destroy' do
      it do
        expect { delete :destroy, :user_id => user, :id => connection.project }.
          to raise_error(CanCan::AccessDenied)
      end
    end
  end
end
