require 'rails_helper'

RSpec.describe ProjectToBoardConnection, :type => :model do
  let(:connection) { create :project_to_board_connection }

  describe '#before_destroy' do
    it do
      expect(IssueToSectionConnection.where(:project_id => connection.tap(&:destroy).project_id,
        :board_id => connection.board_id).size).to eq 0
    end
  end
end
