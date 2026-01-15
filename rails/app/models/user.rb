class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one_attached :profile_pic
  has_one_attached :bio_audio

  # Relationships
  has_many :created_projects, class_name: 'Project', foreign_key: 'created_by_id', dependent: :restrict_with_error
  has_many :created_variation_orders, class_name: 'VariationOrder', foreign_key: 'created_by_id', dependent: :restrict_with_error
  has_many :approved_variation_orders, class_name: 'VariationOrder', foreign_key: 'approved_by_id', dependent: :restrict_with_error
  has_many :submitted_claims, class_name: 'Claim', foreign_key: 'submitted_by_id', dependent: :restrict_with_error
  has_many :uploaded_boqs, class_name: 'Boq', foreign_key: 'uploaded_by_id', dependent: :restrict_with_error

  enum :role, {
    quantity_surveyor: 'quantity_surveyor',
    office: 'office',
    material_buyer: 'material_buyer',
    admin: 'admin'
  }, default: 'quantity_surveyor', suffix: true

  before_create :generate_api_token
  before_validation :sync_admin_flag

  private

  def sync_admin_flag
    self.admin = admin_role?
  end

  def generate_api_token
    self.api_token = SecureRandom.hex(32)
  end
end
