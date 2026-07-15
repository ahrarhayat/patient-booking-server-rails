class Patients::AppointmentsController < ApplicationController
  def index
    appointments = BookingService.list_patient_appointments(params[:patient_id])
    render json: appointments
  rescue StandardError => error
    Rails.logger.error("Failed to fetch patient appointments: #{error.full_message}")
    raise AppError.new("Failed to fetch patient appointments", status: :service_unavailable)
  end
end
