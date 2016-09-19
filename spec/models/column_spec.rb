require 'rails_helper'

RSpec.describe Column, :type => :model do
  let(:column) { create :column }

  describe '#column_issues_for_section' do
    it { expect(column.column_issues_for_section(1).size).to eq 0 }
  end

  describe '#before_destroy' do
    it { expect(column.update_attribute(:tags, column.tags + ['bar'])).to eq true }
  end

  describe '#color_for_column_badge' do
    before { column.update_attribute(:max_issues_count, 10) }

    it { expect(column.color_for_column_badge).to eq 'blue' }
  end
end
