class BookingService
  class << self
    def list_clinicians
      Clinician.bookable.map { |clinician| BookingJson.clinician(clinician) }
    end

    def list_available_slots(clinician_name, from, to)
      clinician = Clinician.bookable.find_by(name: clinician_name)
      raise AppError.new("clinician not found", status: :not_found) if clinician.nil?

      Slot.where(clinician_id: clinician.id, is_available: true)
          .where(start_time: Time.zone.parse(from)...Time.zone.parse(to))
          .order(:start_time)
          .includes(:clinician)
          .map { |slot| BookingJson.slot(slot) }
    end

    def book_appointment(actor:, patient_id:, slot_id:)
      Appointment.transaction do
        unless Patient.exists?(id: patient_id)
          raise AppError.new("patient not found", status: :not_found)
        end

        slot = Slot.lock.find_by(id: slot_id)
        if slot.nil? || !slot.is_available?
          raise AppError.new("slot no longer available", status: :conflict)
        end

        assert_slot_access!(actor, slot.clinician_id)

        unless claim_slot!(slot)
          raise AppError.new("slot no longer available", status: :conflict)
        end

        appointment = Appointment.create!(patient_id: patient_id, slot_id: slot_id)
        appointment = Appointment.includes(slot: :clinician).find(appointment.id)
        BookingJson.appointment(appointment)
      end
    end

    def cancel_appointment(actor:, appointment_id:)
      Appointment.transaction do
        appointment = Appointment.includes(:slot).find_by(id: appointment_id)
        raise AppError.new("appointment not found", status: :not_found) if appointment.nil?

        assert_slot_access!(actor, appointment.slot.clinician_id)

        slot_id = appointment.slot_id
        appointment.destroy!
        release_slot!(slot_id)
      end
    end

    def list_patient_appointments(actor:, patient_id:)
      scope = Appointment.includes(slot: :clinician)
                        .joins(:slot)
                        .where(patient_id: patient_id)
                        .where(slots: { start_time: Time.current.. })
                        .order("slots.start_time ASC")

      scope = scope.where(slots: { clinician_id: actor.id }) unless actor.admin?

      scope.map { |appointment| BookingJson.appointment(appointment) }
    end

    def list_appointments(actor:)
      scope = Appointment.includes(:patient, slot: :clinician)
                        .joins(:slot)
                        .order("slots.start_time ASC")

      scope = scope.where(slots: { clinician_id: actor.id }) unless actor.admin?

      scope.map { |appointment| BookingJson.appointment(appointment) }
    end

    private

    def assert_slot_access!(actor, clinician_id)
      return if actor.admin?
      return if actor.id == clinician_id

      raise AppError.new("forbidden", status: :forbidden)
    end

    def claim_slot!(slot)
      Slot.where(id: slot.id, version: slot.version, is_available: true)
          .update_all(is_available: false, version: slot.version + 1) == 1
    end

    def release_slot!(slot_id)
      Slot.where(id: slot_id).update_all("is_available = TRUE, version = version + 1")
    end
  end
end
