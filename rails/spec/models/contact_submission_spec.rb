require 'rails_helper'

RSpec.describe ContactSubmission, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:company_name) }
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:email) }

    it { should allow_value('test@example.com').for(:email) }
    it { should_not allow_value('not-an-email').for(:email) }
    it { should_not allow_value('@example.com').for(:email) }
  end
end
