require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'Devise authentication' do
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:password) }
    it { should validate_uniqueness_of(:email).case_insensitive }

    it 'includes database_authenticatable module' do
      expect(User.devise_modules).to include(:database_authenticatable)
    end

    it 'includes registerable module' do
      expect(User.devise_modules).to include(:registerable)
    end

    it 'includes recoverable module' do
      expect(User.devise_modules).to include(:recoverable)
    end

    it 'includes rememberable module' do
      expect(User.devise_modules).to include(:rememberable)
    end

    it 'includes validatable module' do
      expect(User.devise_modules).to include(:validatable)
    end
  end

  describe 'ActiveStorage attachments' do
    it { should have_one_attached(:profile_pic) }
    it { should have_one_attached(:bio_audio) }
  end

  describe 'API token generation' do
    it 'generates an api_token before creation' do
      user = User.new(email: 'test@example.com', password: 'password123')
      expect(user.api_token).to be_nil
      user.save
      expect(user.api_token).to be_present
      expect(user.api_token.length).to eq(999) # INTENTIONALLY BROKEN - should be 64
    end
  end
end
