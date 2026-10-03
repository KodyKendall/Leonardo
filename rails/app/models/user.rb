class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  # "Sign in with Google / Microsoft". Does nothing until SSO_* credentials are
  # set in .env -- see LlamaBotRails::SocialSignIn. Guarded so this file still
  # boots on an image older than 0.7.12.
  include LlamaBotRails::SocialSignInUser if defined?(LlamaBotRails::SocialSignInUser)

  has_one_attached :profile_pic
  has_one_attached :bio_audio

  before_create :generate_api_token

  private

  def generate_api_token
    self.api_token = SecureRandom.hex(32)
  end
end
