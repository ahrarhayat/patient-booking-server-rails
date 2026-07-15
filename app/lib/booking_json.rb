module BookingJson
  module_function

  def clinician(clinician)
    {
      id: clinician.id,
      name: clinician.name
    }
  end

  def authenticated_clinician(clinician)
    {
      id: clinician.id,
      name: clinician.name,
      email: clinician.email,
      role: clinician.role
    }
  end

  def patient(patient)
    {
      id: patient.id,
      name: patient.name,
      email: patient.email
    }
  end

  def slot(slot)
    {
      id: slot.id,
      clinicianId: slot.clinician_id,
      clinicianName: slot.clinician.name,
      startTime: slot.start_time.utc.iso8601(3),
      endTime: slot.end_time.utc.iso8601(3),
      isAvailable: slot.is_available
    }
  end

  def appointment(appointment)
    {
      id: appointment.id,
      patientId: appointment.patient_id,
      patientName: appointment.patient.name,
      slotId: appointment.slot_id,
      createdAt: appointment.created_at.utc.iso8601(3),
      slot: slot(appointment.slot)
    }
  end
end

