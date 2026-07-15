class AuthService
  class << self
    def login(name:, password:)
      clinician = Clinician.find_by(name: name)
      unless clinician&.authenticate(password)
        raise AppError.new("invalid name or password", status: :unauthorized)
      end

      {
        token: AuthToken.issue(clinician),
        clinician: BookingJson.authenticated_clinician(clinician)
      }
    end
  end
end
