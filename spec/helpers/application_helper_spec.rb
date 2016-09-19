require 'rails_helper'

describe ApplicationHelper, :type => :helper do
  describe '#edit_navbar_active?' do
    it 'return false' do
      expect(helper.edit_navbar_active?).to eq false
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
end
