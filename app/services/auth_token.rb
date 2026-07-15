class AuthToken
  PURPOSE = :clinician_auth
  EXPIRES_IN = 24.hours

  class << self
    def issue(clinician)
      verifier.generate({ "clinician_id" => clinician.id }, expires_in: EXPIRES_IN, purpose: PURPOSE)
    end

    def verify(token)
      raise AppError.new("unauthorized", status: :unauthorized) if token.blank?

      payload = verifier.verify(token, purpose: PURPOSE)
      clinician_id = payload["clinician_id"] || payload[:clinician_id]
      Clinician.find_by(id: clinician_id) || raise(AppError.new("unauthorized", status: :unauthorized))
    rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveSupport::MessageEncryptor::InvalidMessage
      raise AppError.new("unauthorized", status: :unauthorized)
    end

    private

    def verifier
      Rails.application.message_verifier(PURPOSE)
    end
  end
end
