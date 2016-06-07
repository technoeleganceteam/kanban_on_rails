require 'rails_helper'

RSpec.describe RegistrationsController, :type => :controller do
  it { should route(:post, '/users').to(:action => :create) }

  describe 'POST create' do
    context 'with valid captcha' do
      before do
        request.env['devise.mapping'] = Devise.mappings[:user]

        post :create, :user => attributes_for(:user)
      end

      it { should redirect_to root_url }
    end

    context 'with invalid captcha' do
      before do
        request.env['devise.mapping'] = Devise.mappings[:user]

        Recaptcha.configuration.skip_verify_env.delete('test')

        stub_request(:get, 'https://www.google.com/recaptcha/api/siteverify?' \
          "remoteip=0.0.0.0&response=&secret=#{ Settings.recaptcha.private_key }").
          with(:headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'User-Agent' => 'Ruby' }).
          to_return(:status => 200, :body => '{}', :headers => {})

        post :create, :user => attributes_for(:user)
      end

      it { should render_template :new }
    end
  end
end
