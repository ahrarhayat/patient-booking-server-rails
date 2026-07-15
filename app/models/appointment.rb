class Appointment < ApplicationRecord
  belongs_to :patient
  belongs_to :slot

  validates :slot_id, uniqueness: true
end
