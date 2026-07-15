class AppointmentsController < ApplicationController
  before_action :require_authentication!

  def index
    appointments = BookingService.list_appointments(actor: current_clinician)
    render json: appointments
  rescue AppError
    raise
  rescue StandardError => error
    Rails.logger.error("Failed to fetch appointments: #{error.full_message}")
    raise AppError.new("Failed to fetch appointments", status: :service_unavailable)
  end

  def create
    errors = validate_book_appointment_body
    raise AppError.new("Validation failed", status: :bad_request, details: errors) if errors.any?

    appointment = BookingService.book_appointment(
      actor: current_clinician,
      patient_id: params.require(:patientId),
      slot_id: params.require(:slotId)
    )
    render json: appointment, status: :created
  rescue AppError
    raise
  rescue StandardError => error
    Rails.logger.error("Failed to book appointment: #{error.full_message}")
    raise AppError.new("Failed to book appointment", status: :service_unavailable)
  end

  def destroy
    BookingService.cancel_appointment(actor: current_clinician, appointment_id: params[:id])
    head :no_content
  rescue AppError
    raise
  rescue StandardError => error
    Rails.logger.error("Failed to cancel appointment: #{error.full_message}")
    raise AppError.new("Failed to cancel appointment", status: :service_unavailable)
  end

  private

  def validate_book_appointment_body
    errors = []

    unless params.is_a?(ActionController::Parameters)
      return [ "request body must be an object" ]
    end

    errors << "patientId is required" if params[:patientId].blank?
    errors << "slotId is required" if params[:slotId].blank?
    errors
  end
end
