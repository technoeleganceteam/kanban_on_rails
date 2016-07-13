require 'rails_helper'

RSpec.describe ProjectMailer, :type => :mailer do
  let(:project) { create :project, :emails_for_reports => ['test@mail.com'] }

  let(:changelog) { create :changelog, :project => project }

  let(:mail) { ProjectMailer.changelogs_email([changelog.id]) }

  describe '#changelogs_email' do
    context 'when single release' do
      it 'renders the subject' do
        expect(mail.subject).to eql('Some project release 1.0.0')
      end
    end

    context 'when multiple releases' do
      before do
        @first = create :changelog, :project => project, :tag_name => '1.0.1',
          :last_commit_date => DateTime.now.utc - 1.day

        @second = create :changelog, :project => project, :tag_name => '2.0.0',
          :last_commit_date => DateTime.now.utc
      end

      it 'renders the subject' do
        expect(ProjectMailer.changelogs_email([@first.id, @second.id]).subject).
          to eql('Some project releases 1.0.1 - 2.0.0')
      end
    end

    it 'renders the receiver email' do
      expect(mail.to).to eql(['test@mail.com'])
    end

    it 'renders the sender email' do
      expect(mail.from).to eql(['info@kanbanonrails.com'])
    end
  end
end
