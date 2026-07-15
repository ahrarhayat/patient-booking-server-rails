class PatientService
  class << self
    def create!(name:, email:)
      patient = Patient.new(
        name: name.to_s.strip,
        email: email.to_s.strip.downcase
      )

      unless patient.save
        raise AppError.new(
          "Validation failed",
          status: :bad_request,
          details: patient.errors.full_messages
        )
      end

      BookingJson.patient(patient)
    end
  end
end
