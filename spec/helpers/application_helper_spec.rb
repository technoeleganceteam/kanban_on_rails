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
      @issue = create :issue, :github_labels => [[[], %w(name foo), %w(color bar)]], :tags => ['foo']
    end

    it 'return css rules' do
      expect(helper.issue_tag_color(@issue, 'foo')).to eq 'background-color: #bar;color:black;'
    end
  end

  describe '#show_start_sync_button' do
    before { @user = create :user }

    it 'return nil' do
      expect(helper.show_start_sync_button(@user, 'github')).to eq nil
    end
  end

  describe '#show_stop_sync_button' do
    before { @user = create :user }

    it 'return nil' do
      expect(helper.show_stop_sync_button(@user, 'github')).to eq nil
    end
  end

  describe '#gitlab_issue_link' do
    it { expect(helper.gitlab_issue_link('test', '1')).to eq 'https://gitlab.com/test/issues/1' }
  end

  describe '#bitbucket_issue_link' do
    it { expect(helper.bitbucket_issue_link('test', '1')).to eq 'https://bitbucket.com/test/issues/1' }
  end

  describe '#feedback_form_name' do
    context 'when name is present' do
      before { @feedback = Feedback.new(:name => 'test') }

      it { expect(helper.feedback_form_name(@feedback)).to eq 'test' }
    end

    context 'when name is not present' do
      before { @feedback = Feedback.new }

      it { expect(helper.feedback_form_name(@feedback)).to eq nil }
    end
  end

  describe '#feedback_form_email' do
    context 'when email is present' do
      before { @feedback = Feedback.new(:email => 'test@mail.com') }

      it { expect(helper.feedback_form_email(@feedback)).to eq 'test@mail.com' }
    end

    context 'when email is not present' do
      before { @feedback = Feedback.new }

      it { expect(helper.feedback_form_email(@feedback)).to eq nil }
    end
  end

  describe '#subtask_info_for_report' do
    before { @subtask = create :pull_request_subtask }

    it { expect(helper.subtask_info_for_report(@subtask)).to eq "Subtask description \n" }
  end

  describe '#pull_request_info_for_report' do
    before { @pull_request = create :pull_request, :gitlab_url => 'https://gitlab.com/test' }

    it do
      expect(helper.pull_request_info_for_report(@pull_request)).
        to eq "Some title ([#](https://gitlab.com/test) by [@]()) \n"
    end
  end

  describe '#issue_info_for_report' do
    before { @issue = create :issue, :gitlab_issue_id => '1' }

    it { expect(helper.issue_info_for_report(@issue)).to eq "Some title ([#](https://gitlab.com//issues/))\n" }
  end
end
