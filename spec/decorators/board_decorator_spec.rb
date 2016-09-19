require 'rails_helper'

describe BoardDecorator, :type => :decorator do
  let(:board) { BoardDecorator.new(create(:board)) }

  describe '#section_width' do
    it { expect(board.section_width).to eq 0 }
  end

  describe '#ordered_columns' do
    it { expect(board.ordered_columns.size).to eq 0 }
  end

  describe 'ordered_sections' do
    it { expect(board.ordered_sections.size).to eq 0 }
  end
end
