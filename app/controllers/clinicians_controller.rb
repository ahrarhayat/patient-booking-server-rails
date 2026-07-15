class CliniciansController < ApplicationController
  def index
    clinicians = BookingService.list_clinicians
    render json: clinicians
  rescue AppError
    raise
  rescue StandardError => error
    Rails.logger.error("Failed to fetch clinicians: #{error.full_message}")
    raise AppError.new("Failed to fetch clinicians", status: :service_unavailable)
  end
end
