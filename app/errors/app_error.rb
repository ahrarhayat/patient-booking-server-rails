class AppError < StandardError
  attr_reader :status, :details

  def initialize(message, status: :internal_server_error, details: nil)
    super(message)
    @status = status
    @details = details
  end
end
