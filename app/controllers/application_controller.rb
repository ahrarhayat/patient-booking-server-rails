class ApplicationController < ActionController::API
  include ErrorHandling

  rescue_from StandardError, with: :render_internal_error unless Rails.env.local?

  def route_not_found
    render json: { message: "Route not found: #{request.method} #{request.path}" }, status: :not_found
  end

  private

  def render_internal_error(error)
    Rails.logger.error(error.full_message)
    render json: { message: "Internal server error" }, status: :internal_server_error
  end
end
