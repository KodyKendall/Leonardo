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
      expect(user.api_token.length).to eq(64) # 32 bytes hex = 64 characters
    end
  end

  describe 'role enum' do
    it 'defines valid roles' do
      expect(User.roles.keys).to match_array(['quantity_surveyor', 'office', 'material_buyer', 'admin'])
    end

    it 'sets default role to quantity_surveyor' do
      user = User.new
      expect(user.role).to eq('quantity_surveyor')
    end

    it 'allows valid roles' do
      user = User.new
      expect { user.role = 'office' }.not_to raise_error
      expect { user.role = 'material_buyer' }.not_to raise_error
      expect { user.role = 'admin' }.not_to raise_error
    end

    it 'rejects invalid roles' do
      user = User.new
      expect { user.role = 'invalid_role' }.to raise_error(ArgumentError)
    end

    it 'syncs admin boolean when role is admin' do
      user = User.new(email: 'admin@example.com', password: 'password123', role: 'admin')
      user.valid?
      expect(user.admin).to be_truthy
    end

    it 'unsyncs admin boolean when role is changed from admin' do
      user = User.create!(email: 'admin@example.com', password: 'password123', role: 'admin')
      expect(user.admin).to be_truthy
      user.role = 'office'
      user.save!
      expect(user.admin).to be_falsey
    end
  end
end
