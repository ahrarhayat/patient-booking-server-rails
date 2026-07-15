ENV["RAILS_ENV"] ||= "test"
ENV.delete("DATABASE_URL")
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Integration tests use fixed unique emails/names; parallel DBs are easy
    # to misconfigure with Docker Postgres and produce uniqueness collisions.
    parallelize(workers: 1)
    fixtures :all
  end
end
