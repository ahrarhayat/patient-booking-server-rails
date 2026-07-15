ENV["RAILS_ENV"] ||= "test"
ENV.delete("DATABASE_URL")
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Keep this suite single-process. Parallel workers share one Postgres DB when
    # per-worker DBs are not provisioned, which breaks unique email/name setup.
  end
end
