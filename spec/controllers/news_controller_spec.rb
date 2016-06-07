require 'rails_helper'

RSpec.describe NewsController, :type => :controller do
  it { should route(:get, '/news').to(:action => :index) }

  it { should route(:get, '/news/1').to(:action => :show, :id => 1) }

  describe 'GET index' do
    before { get :index }

    it { should render_template :index }
  end

  describe 'GET show' do
    before { get :show, :id => '1_we_have_just_launched_our_service' }

    it { should render_template '1_we_have_just_launched_our_service' }
  end
end
