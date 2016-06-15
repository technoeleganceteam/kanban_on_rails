require 'rails_helper'

RSpec.describe Project, :type => :model do
  let(:project) { create :project }

  describe '#parse_issue_params_from_github_webhook' do
    it do
      expect(project.parse_issue_params_from_github_webhook(:id => 1, :number => 1,
      :title => 'Some totle', :labels => [{ :some => 'label' }])).to eq true
    end
  end

  describe '#parse_issue_params_from_bitbucket_webhook' do
    it do
      expect(project.parse_issue_params_from_bitbucket_webhook(:id => 1, :title => 'Some title',
      :content => { :raw => 'content' })).to eq true
    end
  end

  describe '#parse_issue_params_from_gitlab_webhook' do
    it { expect(project.parse_issue_params_from_gitlab_webhook(:id => 1, :title => 'Some title')).to eq true }
  end

  describe '#open_issues' do
    it { expect(project.open_issues).to eq 0 }
  end
end
