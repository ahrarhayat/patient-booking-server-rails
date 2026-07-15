namespace :db do
  desc "Start local PostgreSQL via Docker Compose, migrate, and seed default data"
  task :up do
    system("docker compose up -d") || abort("Failed to start database")
    system("bin/rails db:prepare db:seed") || abort("Failed to prepare database")
    puts "PostgreSQL started with Docker"
    puts "DATABASE_URL=postgresql://booking:booking@localhost:5434/patient_booking_rails"
  end

  desc "Stop local PostgreSQL via Docker Compose"
  task :down do
    system("docker compose down") || abort("Failed to stop database")
    puts "Docker PostgreSQL stopped"
  end
end
