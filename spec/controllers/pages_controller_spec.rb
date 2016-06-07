require 'rails_helper'

RSpec.describe PagesController, :type => :controller do
  it { should route(:get, '/pages/1').to(:action => :show, :id => 1) }

  describe 'GET show' do
    before { get :show, :id => 'faq' }

    it { should render_template :faq }
  end

  describe 'GET robots' do
    before { get :robots, :format => :txt }

    it {expect(response.body.size).to eq 26 }
  end
end
