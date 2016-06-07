require 'rails_helper'

describe ApplicationHelper, :type => :helper do
  describe '#edit_navbar_active?' do
    it 'return false' do
      expect(helper.edit_navbar_active?).to eq false
    end
  end

  describe '#language_options_for_settings_select' do
    it 'return false' do
      expect(helper.language_options_for_settings_select.size).to eq 71
    end
  end

  describe '#color_for_column_badge' do
    before { @column = create :column, :max_issues_count => 10 }

    it 'return blue' do
      expect(helper.color_for_column_badge(@column)).to eq 'blue'
    end
  end

  describe '#issue_tag_color' do
    before do
      @issue = create :issue, :github_labels => [[[], ['name', 'foo'], ['color', 'bar']]], :tags => ['foo']
    end

    it 'return css rules' do
      expect(helper.issue_tag_color(@issue, 'foo')).to eq 'background-color: #bar;color:black;'
    end
  end
end
