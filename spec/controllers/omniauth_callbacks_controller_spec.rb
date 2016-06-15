require 'rails_helper'

RSpec.describe OmniauthCallbacksController, :type => :controller do
  it { should route(:get, '/users/auth/github/callback').to(:action => :github) }

  it { should route(:post, '/users/auth/github/callback').to(:action => :github) }

  describe 'GET github' do
    context 'when email present' do
      before do
        request.env['devise.mapping'] = Devise.mappings[:user]

        request.env['omniauth.auth'] = { :uid => 1, :credentials => { :token => 'token' },
          :info => { :email => 'test@test.com' }, :provider => :github }

        get :github
      end

      it { should redirect_to dashboard_user_url(assigns(:authentication).user) }
    end

    context 'when email not present' do
      before do
        request.env['devise.mapping'] = Devise.mappings[:user]

        request.env['omniauth.auth'] = { :uid => 1, :credentials => { :token => 'token' },
          :info => { :email => '' }, :provider => :github }

        get :github
      end

      it { should redirect_to root_url }
    end
  end
end
