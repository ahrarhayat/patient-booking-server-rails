class Clinician < ApplicationRecord
  has_secure_password

  has_many :slots, dependent: :restrict_with_error

  enum :role, { clinician: "clinician", admin: "admin" }, validate: true

  validates :name, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
  validates :password, length: { minimum: 8 }, if: -> { password.present? }

  scope :bookable, -> { clinician.order(:name) }
end
