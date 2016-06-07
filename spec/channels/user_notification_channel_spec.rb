require 'rails_helper'

describe UserNotificationsChannel do
  describe '#subscribed' do
    subject { UserNotificationsChannel.new(ApplicationCable::Connection.
      new(ActionCable::Server::Base.new(), {}), { :foo => 'bar' }) } 

    before do
      user = create :user

      allow_any_instance_of(ActionCable::Connection::WebSocket).to receive(:transmit).
        with(an_instance_of(String)).and_return('foo')
      allow_any_instance_of(ApplicationCable::Connection).to receive(:current_user).and_return(user)
    end

    it { expect(UserNotificationsChannel.new(ApplicationCable::Connection.
      new(ActionCable::Server::Base.new(), {}), { :foo => 'bar' }).subscribed).to eq nil }
  end
end
