require 'rails_helper'

RSpec.describe Authentication, :type => :model do
  describe '#update_user_meta' do
    it 'should update update user meta field' do
      user = create(:user)

      authentication = create(:authentication, :user => user, :uid => '123')

      expect(authentication.run_callbacks(:commit)).to eq true
    end
  end
end
