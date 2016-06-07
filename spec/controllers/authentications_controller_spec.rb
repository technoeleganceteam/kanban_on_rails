require 'rails_helper'

RSpec.describe AuthenticationsController, :type => :controller do
  let(:user) { create :user }

  let(:authentication) { create :authentication, :user => user }

  it { should route(:get, '/users/1/authentications').to(:action => :index, :user_id => 1) }

  it { should route(:delete, '/users/1/authentications/1').to(:action => :destroy, :id => 1, :user_id => 1) }

  it { expect { get :index, :user_id => user }.to raise_error(CanCan::AccessDenied) }

  it { expect { delete :destroy, :id => authentication, :user_id => user }.to raise_error(CanCan::AccessDenied) }

  it { expect { get :index, :user_id => user }.to raise_error(CanCan::AccessDenied) }

  it { expect { delete :destroy, :id => authentication, :user_id => user }.to raise_error(CanCan::AccessDenied) }

  context 'User' do
    before { sign_in user }

    describe 'GET index' do
      before { get :index, :user_id => user }

      it { should redirect_to new_user_session_url(:locale => nil) }
    end

    describe 'DELETE destroy' do
      before { delete :destroy, :user_id => user, :id => authentication }

      it { should redirect_to new_user_session_url(:locale => nil) }
    end
  end

  context 'Confirmed user' do
    before { sign_in user; user.confirm }

    describe 'GET index' do
      before { get :index, :user_id => user }

      it { should render_template :index }

      it { expect(assigns(:user)).not_to be_nil }

      it { expect(assigns(:authentications)).not_to be_nil }
    end

    describe 'DELETE destroy' do
      before { delete :destroy, :id => authentication, :user_id => user, :format => :js }

      it { should redirect_to user_authentications_url(assigns(:user)) }

      it { expect(assigns(:user)).not_to be_nil }

      it { expect(assigns(:authentication)).not_to be_nil }
    end
  end
end
