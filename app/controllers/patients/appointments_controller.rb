class Patients::AppointmentsController < ApplicationController
  before_action :require_authentication!

  def index
    appointments = BookingService.list_patient_appointments(
      actor: current_clinician,
      patient_id: params[:patient_id]
    )
    render json: appointments
  rescue AppError
    raise
  rescue StandardError => error
    Rails.logger.error("Failed to fetch patient appointments: #{error.full_message}")
    raise AppError.new("Failed to fetch patient appointments", status: :service_unavailable)
  end
end
