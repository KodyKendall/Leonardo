class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one_attached :profile_pic
  has_one_attached :bio_audio

  before_create :generate_api_token

  private

  def generate_api_token
    self.api_token = SecureRandom.hex(32)
  end
end
