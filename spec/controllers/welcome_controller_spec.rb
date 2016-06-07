require 'rails_helper'

RSpec.describe WelcomeController, :type => :controller do
  let(:user) { create :user, :password => 'some1234' }

  describe 'GET index' do
    context 'with locale and signed in user' do
      before do
        user.update_attributes(:confirmed_at => DateTime.now)

        sign_in user

        get :index, :locale => 'ru'
      end

      it { expect(I18n.locale).to eq :ru }
    end

    context 'with locale and signed in user' do
      before do
        session[:locale] = 'en'

        get :index
      end

      it { expect(I18n.locale).to eq :en }
    end
  end
end
