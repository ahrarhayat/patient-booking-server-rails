class AuthController < ApplicationController
  before_action :require_authentication!, only: :me

  def create
    email = params[:email].to_s.strip.downcase
    password = params[:password].to_s

    errors = []
    errors << "email is required" if email.blank?
    errors << "password is required" if password.blank?
    raise AppError.new("Validation failed", status: :bad_request, details: errors) if errors.any?

    result = AuthService.login(email: email, password: password)
    render json: result
  end

  def me
    render json: BookingJson.authenticated_clinician(current_clinician)
  end
end
