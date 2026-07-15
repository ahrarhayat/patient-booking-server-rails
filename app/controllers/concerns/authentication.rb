module Authentication
  extend ActiveSupport::Concern

  private

  def current_clinician
    return @current_clinician if defined?(@current_clinician)

    @current_clinician = authenticate_clinician_from_token
  end

  def require_authentication!
    raise AppError.new("unauthorized", status: :unauthorized) if current_clinician.nil?
  end

  def require_admin!
    require_authentication!
    raise AppError.new("forbidden", status: :forbidden) unless current_clinician.admin?
  end

  def authenticate_clinician_from_token
    AuthToken.verify(bearer_token)
  rescue AppError
    nil
  end

  def bearer_token
    header = request.headers["Authorization"].to_s
    return header.delete_prefix("Bearer ").strip if header.start_with?("Bearer ")

    nil
  end
end
