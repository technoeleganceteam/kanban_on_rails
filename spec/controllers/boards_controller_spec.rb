require 'rails_helper'

RSpec.describe BoardsController, :type => :controller do
  let(:user) { create :user }

  let(:project) { create :project }

  let(:board) { create :board }

  let(:connection) { create :project_to_board_connection, :project => project, :board => board }

  let(:user_to_board_connection) do
    create :user_to_board_connection, :user_id => user.id, :board => board, :role => 'owner'
  end

  let(:another_user) { create :user }

  it { should route(:get, '/boards/1').to(:action => :show, :id => 1) }

  it { should route(:get, '/users/1/boards').to(:action => :index, :user_id => 1) }

  it { should route(:get, '/users/1/boards/new').to(:action => :new, :user_id => 1) }

  it { should route(:post, '/users/1/boards').to(:action => :create, :user_id => 1) }

  it { should route(:get, '/users/1/boards/1/edit').to(:action => :edit, :id => 1, :user_id => 1) }

  it { should route(:patch, '/users/1/boards/1').to(:action => :update, :id => 1, :user_id => 1) }

  it { should route(:put, '/users/1/boards/1').to(:action => :update, :id => 1, :user_id => 1) }

  it { should route(:delete, '/users/1/boards/1').to(:action => :destroy, :id => 1, :user_id => 1) }

  it { expect { get :index, :user_id => user }.to raise_error(CanCan::AccessDenied) }

  it { expect { get :show, :id => board }.to raise_error(CanCan::AccessDenied) }

  it { expect { get :edit, :id => board, :user_id => user }.to raise_error(CanCan::AccessDenied) }

  it { expect { post :create, :user_id => user }.to raise_error(CanCan::AccessDenied) }

  it { expect { put :update, :user_id => user, :id => connection.board }.to raise_error(CanCan::AccessDenied) }

  it { expect { patch :update, :user_id => user, :id => connection.board }.to raise_error(CanCan::AccessDenied) }

  it do
    expect { delete :destroy, :user_id => user, :id => connection.board }.
      to raise_error(CanCan::AccessDenied)
  end

  context 'Confirmed user' do
    before { sign_in user; user.confirm }

    describe 'GET show' do
      before { get :show, :id => user_to_board_connection.board }

      it { should render_template :show }
    end

    describe 'GET edit' do
      before { get :edit, :id => user_to_board_connection.board, :user_id => user }

      it { should render_template :edit }
    end

    describe 'GET index' do
      before { get :index, :user_id => user }

      it { should render_template :index }
    end

    describe 'POST create' do
      context 'with valid attributes' do
        before { post :create, :user_id => user, :board => { :name => 'Some name' }, :format => :js }

        it do
          expect(response.body).to eq(
            "Turbolinks.visit('http://test.host/boards/#{ assigns(:board).id }');"
          )
        end
      end

      context 'with invalid attributes' do
        before { post :create, :user_id => user, :board => { :name => '' }, :format => :js }

        it { should render_template :new }
      end
    end

    describe 'PATCH update as JS' do
      context 'with valid attributes' do
        before do
          put :update, :user_id => user, :id => user_to_board_connection.board,
          :board => { :name => 'Some name2' }, :format => :js
        end

        it do
          expect(response.body).to eq(
            "Turbolinks.visit('http://test.host/boards/#{ assigns(:board).id }');"
          )
        end
      end

      context 'with invalid attributes' do
        before do
          put :update, :user_id => user, :id => user_to_board_connection.board,
          :board => { :name => '' }, :format => :js
        end

        it { should render_template :edit }
      end

      context 'with attributes for columns with overlapping tags' do
        before do
          put :update, :user_id => user, :id => user_to_board_connection.board,
            :board => { :name => 'Some name', :columns_attributes =>
              { '0' => { :name => 'Some name', :tags => ['bar'] },
                '1' => { :name => 'Some name', :tags => ['bar'] } } }, :format => :js
        end

        it { should render_template :edit }
      end

      context 'with attributes for issues_to_section_connection and section' do
        before do
          section = create :section, :board => user_to_board_connection.board

          issue = create :issue

          issue.project.boards << user_to_board_connection.board

          issue.save

          issue_connection = create :issue_to_section_connection, :issue => issue, :section => section,
            :board => user_to_board_connection.board

          put :update, :user_id => user, :id => user_to_board_connection.board,
            :board => { :name => 'Some name', :issues_to_section_connections_attributes =>
              { '0' => { :id => issue_connection.id, :issue_order => 1 } },
              :sections_attributes => { '0' => { :id => section.id, :name => 'Bar' } } }, :format => :js
        end

        it do
          expect(response.body).to eq(
            "Turbolinks.visit('http://test.host/boards/#{ assigns(:board).id }');"
          )
        end
      end

      context 'with attributes for issues' do
        before do
          section = create :section, :board => user_to_board_connection.board

          issue = create :issue

          create :issue_to_section_connection, :issue => issue, :section => section,
            :board => user_to_board_connection.board

          put :update, :user_id => user, :id => user_to_board_connection.board,
            :board => { :name => 'Some name', :issues_attributes =>
              { '0' => { :id => issue.id, :tags => %w(foo bar) } } }, :format => :js
        end

        it do
          expect(response.body).to eq(
            "Turbolinks.visit('http://test.host/boards/#{ assigns(:board).id }');"
          )
        end
      end

      context 'with attributes for issues and when issue connected to github' do
        before do
          issue = create :issue

          issue.github_issue_id = 123

          issue.save

          section = create :section, :board => user_to_board_connection.board

          create :issue_to_section_connection, :issue => issue, :section => section,
            :board => user_to_board_connection.board

          put :update, :user_id => user, :id => user_to_board_connection.board,
            :board => { :name => 'Some name', :issues_attributes =>
              { '0' => { :id => issue.id, :tags => %w(foo bar) } } }, :format => :js
        end

        it do
          expect(response.body).to eq(
            "Turbolinks.visit('http://test.host/boards/#{ assigns(:board).id }');"
          )
        end
      end

      context 'with attributes for issues when issue in multiple sections' do
        before do
          issue = create :issue, :tags => %w(foo tag)

          section_first = create :section, :tags => ['foo'], :board => user_to_board_connection.board

          section_second = create :section, :tags => ['bar'], :board => user_to_board_connection.board

          create :column, :tags => ['tag'], :board => user_to_board_connection.board

          create :issue_to_section_connection, :issue => issue,
            :section => section_first, :board => user_to_board_connection.board

          create :issue_to_section_connection, :issue => issue,
            :section => section_second, :board => user_to_board_connection.board

          put :update, :user_id => user, :id => user_to_board_connection.board,
            :board => { :name => 'Some name', :issues_attributes =>
              { '0' => { :id => issue.id, :tags => %w(foo bar) } } }, :format => :js
        end

        it do
          expect(response.body).to eq(
            "Turbolinks.visit('http://test.host/boards/#{ assigns(:board).id }');"
          )
        end
      end

      context 'with attributes for issues when issue in include all section' do
        before do
          section = create :section, :include_all => true, :board => board

          create :section, :tags => ['bar'], :board => board

          create :column, :tags => ['tag'], :board => board

          issue = create :issue, :tags => %w(foo tag)

          create :issue_to_section_connection, :issue => issue,
            :section => section, :board => user_to_board_connection.board

          put :update, :user_id => user, :id => user_to_board_connection.board,
            :board => { :name => 'Some name', :issues_attributes =>
              { '0' => { :id => issue.id, :tags => %w(foo bar) } } }, :format => :js
        end

        it do
          expect(response.body).to eq(
            "Turbolinks.visit('http://test.host/boards/#{ assigns(:board).id }');"
          )
        end
      end
    end

    describe 'DELETE destroy' do
      before { delete :destroy, :user_id => user, :id => user_to_board_connection.board }

      it { should redirect_to user_boards_url(assigns(:user)) }
    end
  end

  context 'Confirmed another user' do
    before { sign_in another_user; another_user.confirm }

    describe 'GET show board of first user' do
      it { expect { get :show, :id => connection.board }.to raise_error(CanCan::AccessDenied) }
    end

    describe 'GET edit board of first user' do
      it { expect { get :edit, :id => connection.board, :user_id => user }.to raise_error(CanCan::AccessDenied) }
    end

    describe 'GET index of user first boards' do
      it { expect { get :index, :user_id => user }.to raise_error(CanCan::AccessDenied) }
    end

    describe 'POST create board for first user' do
      it do
        expect { post :create, :user_id => user, :board => { :name => 'Some name' }, :format => :js }.
          to raise_error(CanCan::AccessDenied)
      end
    end

    describe 'PUT update board for first user' do
      it do
        expect do
          put :update, :user_id => user, :id => connection.board,
     :board => { :name => 'Some name2' }, :format => :js
        end.
          to raise_error(CanCan::AccessDenied)
      end
    end

    describe 'DELETE destroy' do
      it do
        expect { delete :destroy, :user_id => user, :id => connection.board }.
          to raise_error(CanCan::AccessDenied)
      end
    end
  end
end
