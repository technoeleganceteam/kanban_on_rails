require 'rails_helper'

RSpec.describe ApplicationController, :type => :controller do
  controller(DeviseController) do
    def configure_permitted_parameters
      super
    end
  end

  before :each do
    request.env['devise.mapping'] = Devise.mappings[:user]
  end

  describe '#configure_permitted_parameters' do
    subject { controller.configure_permitted_parameters }

    it { should eq [:email, :password, :password_confirmation, :name, :locale] }
  end
end
