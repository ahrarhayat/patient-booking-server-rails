class AuthService
  class << self
    def login(email:, password:)
      clinician = Clinician.find_by(email: email.to_s.strip.downcase)
      unless clinician&.authenticate(password)
        raise AppError.new("invalid email or password", status: :unauthorized)
      end

      {
        token: AuthToken.issue(clinician),
        clinician: BookingJson.authenticated_clinician(clinician)
      }
    end
  end
end
