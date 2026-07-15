class AuthController < ApplicationController
  before_action :require_authentication!, only: :me

  def create
    name = params[:name].to_s.strip
    password = params[:password].to_s

    errors = []
    errors << "name is required" if name.blank?
    errors << "password is required" if password.blank?
    raise AppError.new("Validation failed", status: :bad_request, details: errors) if errors.any?

    result = AuthService.login(name: name, password: password)
    render json: result
  end

  def me
    render json: BookingJson.authenticated_clinician(current_clinician)
  end
end
