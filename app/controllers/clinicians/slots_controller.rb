class Clinicians::SlotsController < ApplicationController
  def index
    from = params[:from]
    to = params[:to]
    errors = validate_slot_range_query(from, to)

    if errors.any?
      raise AppError.new(errors.first, status: :bad_request, details: errors)
    end

    slots = BookingService.list_available_slots(params[:name], from, to)
    render json: slots
  rescue AppError
    raise
  rescue StandardError => error
    Rails.logger.error("Failed to fetch clinician slots: #{error.full_message}")
    raise AppError.new("Failed to fetch clinician slots", status: :service_unavailable)
  end

  private

  def validate_slot_range_query(from, to)
    errors = []

    errors << "from query parameter is required" if from.blank?
    errors << "to query parameter is required" if to.blank?
    return errors if errors.any?

    errors << "from must be a valid ISO date" if parse_time(from).nil?
    errors << "to must be a valid ISO date" if parse_time(to).nil?
    errors
  end

  def parse_time(value)
    Time.zone.parse(value)
  rescue ArgumentError, TypeError
    nil
  end
end
