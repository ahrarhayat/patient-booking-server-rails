class CliniciansController < ApplicationController
  before_action :require_admin!, only: :create

  def index
    clinicians = BookingService.list_clinicians
    render json: clinicians
  rescue AppError
    raise
  rescue StandardError => error
    Rails.logger.error("Failed to fetch clinicians: #{error.full_message}")
    raise AppError.new("Failed to fetch clinicians", status: :service_unavailable)
  end

  def create
    errors = validate_create_body
    raise AppError.new("Validation failed", status: :bad_request, details: errors) if errors.any?

    clinician = ClinicianService.create!(
      name: params[:name],
      email: params[:email],
      password: params[:password],
      role: params.fetch(:role, :clinician)
    )
    render json: clinician, status: :created
  rescue AppError
    raise
  rescue StandardError => error
    Rails.logger.error("Failed to create clinician: #{error.full_message}")
    raise AppError.new("Failed to create clinician", status: :service_unavailable)
  end

  private

  def validate_create_body
    errors = []

    unless params.is_a?(ActionController::Parameters)
      return [ "request body must be an object" ]
    end

    errors << "name is required" if params[:name].blank?
    errors << "email is required" if params[:email].blank?
    errors << "password is required" if params[:password].blank?
    errors
  end
end
