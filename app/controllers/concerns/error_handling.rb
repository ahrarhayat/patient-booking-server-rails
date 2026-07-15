module ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from AppError, with: :render_app_error
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActionController::ParameterMissing, with: :render_bad_request
    rescue_from ActionDispatch::Http::Parameters::ParseError, with: :render_invalid_json
  end

  private

  def render_app_error(error)
    payload = { message: error.message }
    payload[:details] = error.details if error.details.present?
    render json: payload, status: error.status
  end

  def render_not_found
    render json: { message: "Route not found: #{request.method} #{request.path}" }, status: :not_found
  end

  def render_bad_request(error)
    render json: { message: error.message }, status: :bad_request
  end

  def render_invalid_json
    render json: { message: "Invalid JSON in request body" }, status: :bad_request
  end
end
