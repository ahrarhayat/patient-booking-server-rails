class Slot < ApplicationRecord
  belongs_to :clinician
  has_one :appointment, dependent: :restrict_with_error

  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :is_available, inclusion: { in: [ true, false ] }
  validates :version, presence: true
end
