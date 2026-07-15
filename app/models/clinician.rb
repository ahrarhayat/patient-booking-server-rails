class Clinician < ApplicationRecord
  has_many :slots, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
end
