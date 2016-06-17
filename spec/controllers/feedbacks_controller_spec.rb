require 'rails_helper'

RSpec.describe FeedbacksController, :type => :controller do
  it { should route(:get, '/feedbacks/new').to(:action => :new) }

  it { should route(:post, '/feedbacks').to(:action => :create) }

  describe 'GET new' do
    before { get :new }

    it { should render_template :new }
  end

  describe 'POST create as JS' do
    context 'with valid attributes' do
      before { post :create, :feedback => { :content => '' }, :format => :js }

      it { should render_template 'new' }
    end

    context 'with invalid attributes' do
      before do
        post :create, :feedback => { :content => 'Some content',
          :email => 'some@mail.com', :name => 'Some name' }, :format => :js
      end

      it { should render_template 'create' }
    end
  end
end
