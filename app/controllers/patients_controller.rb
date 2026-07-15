class PatientsController < ApplicationController
  before_action :require_authentication!

  def index
    patients = BookingService.list_patients
    render json: patients
  rescue AppError
    raise
  rescue StandardError => error
    Rails.logger.error("Failed to fetch patients: #{error.full_message}")
    raise AppError.new("Failed to fetch patients", status: :service_unavailable)
  end

  def create
    errors = validate_create_body
    raise AppError.new("Validation failed", status: :bad_request, details: errors) if errors.any?

    patient = PatientService.create!(
      name: params[:name],
      email: params[:email]
    )
    render json: patient, status: :created
  rescue AppError
    raise
  rescue StandardError => error
    Rails.logger.error("Failed to create patient: #{error.full_message}")
    raise AppError.new("Failed to create patient", status: :service_unavailable)
  end

  private

  def validate_create_body
    errors = []

    unless params.is_a?(ActionController::Parameters)
      return [ "request body must be an object" ]
    end

    errors << "name is required" if params[:name].blank?
    errors << "email is required" if params[:email].blank?
    errors
  end
end
