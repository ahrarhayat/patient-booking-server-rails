class ClinicianService
  class << self
    def create!(name:, email:, password:, role: :clinician)
      role = role.to_s.presence || "clinician"
      unless Clinician.roles.key?(role)
        raise AppError.new("Validation failed", status: :bad_request, details: [ "role must be clinician or admin" ])
      end

      clinician = Clinician.new(
        name: name.to_s.strip,
        email: email.to_s.strip.downcase,
        password: password,
        role: role
      )

      unless clinician.save
        raise AppError.new(
          "Validation failed",
          status: :bad_request,
          details: clinician.errors.full_messages
        )
      end

      BookingJson.authenticated_clinician(clinician)
    end
  end
end
