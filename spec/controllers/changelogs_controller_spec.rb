require 'rails_helper'

RSpec.describe ChangelogsController, :type => :controller do
  let(:user) { create :user }

  let(:project) { create :project }

  let(:changelog) { create :changelog, :project => project }

  it { should route(:get, '/projects/1/changelogs').to(:action => :index, :project_id => 1) }

  it { should route(:get, '/projects/1/changelogs/1').to(:action => :show, :project_id => 1, :id => 1) }

  it do
    should route(:get, '/projects/1/changelogs/1/resend').
      to(:action => :resend, :project_id => 1, :id => 1)
  end

  it { should route(:get, '/projects/1/changelogs/sync').to(:action => :sync, :project_id => 1) }

  context 'Confirmed user' do
    before do
      sign_in user

      user.confirm

      user.user_to_project_connections << (create :user_to_project_connection, :user => user, :project => project)
    end

    describe 'GET index' do
      before { get :index, :project_id => project }

      it { should render_template :index }
    end

    describe 'GET show' do
      before { get :show, :project_id => project, :id => changelog }

      it { should render_template :show }
    end

    describe 'GET show as TEXT' do
      before { get :show, :project_id => project, :id => changelog, :format => :text }

      it { should render_template :show }
    end

    describe 'GET sync' do
      before { get :sync, :project_id => project }

      it { should redirect_to project_changelogs_url(assigns(:project)) }
    end

    describe 'GET resend' do
      before { get :resend, :project_id => project, :id => changelog }

      it { should redirect_to project_changelogs_url(assigns(:project)) }
    end
  end
end
