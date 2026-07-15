class HealthController < ApplicationController
  def show
    ActiveRecord::Base.connection.execute("SELECT 1")
    render json: { status: "ok", database: "connected" }
  rescue StandardError
    render json: { status: "degraded", database: "disconnected" }, status: :service_unavailable
  end
end
