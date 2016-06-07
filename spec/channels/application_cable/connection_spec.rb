require 'rails_helper'

describe ApplicationCable::Connection do
  describe '#connect' do
    it { expect { ApplicationCable::Connection.new(ActionCable::Server::Base.new(), {}).connect }.
      to raise_error(ActionCable::Connection::Authorization::UnauthorizedError) }
  end
end
