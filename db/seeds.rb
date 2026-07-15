DEFAULT_PATIENT_ID = "a0000000-0000-4000-8000-000000000001"
DEFAULT_PASSWORD = "password123"
ADMIN_PASSWORD = "admin123"

ADMIN = {
  id: "b0000000-0000-4000-8000-000000000099",
  name: "Admin",
  email: "admin@clinic.example.com",
  role: :admin,
  password: ADMIN_PASSWORD
}.freeze

CLINICIANS = [
  {
    id: "b0000000-0000-4000-8000-000000000001",
    name: "Dr. Sam Clinician",
    email: "sam@clinic.example.com"
  },
  {
    id: "b0000000-0000-4000-8000-000000000002",
    name: "Dr. Ada Clinician",
    email: "ada@clinic.example.com"
  },
  {
    id: "b0000000-0000-4000-8000-000000000003",
    name: "Dr. Jordan Lee",
    email: "jordan@clinic.example.com"
  },
  {
    id: "b0000000-0000-4000-8000-000000000004",
    name: "Dr. Priya Shah",
    email: "priya@clinic.example.com"
  },
  {
    id: "b0000000-0000-4000-8000-000000000005",
    name: "Dr. Morgan Ellis",
    email: "morgan@clinic.example.com"
  }
].freeze

DEFAULT_CLINICIAN_NAME = CLINICIANS.first[:name]

def add_days(base, days)
  base + days.days
end

def at_time(date, hours, minutes = 0)
  date.in_time_zone.change(hour: hours, min: minutes, sec: 0)
end

def create_slot_seed(id, clinician_id, day_offset, start_hour, duration_minutes)
  day = add_days(Time.zone.today, day_offset)
  start = at_time(day, start_hour)
  end_time = start + duration_minutes.minutes

  {
    id: id,
    clinician_id: clinician_id,
    start_time: start,
    end_time: end_time,
    is_available: true
  }
end

def upsert_clinician!(attrs)
  Clinician.find_or_initialize_by(id: attrs[:id]).tap do |clinician|
    clinician.name = attrs[:name]
    clinician.email = attrs[:email]
    clinician.role = attrs.fetch(:role, :clinician)
    clinician.password = attrs.fetch(:password, DEFAULT_PASSWORD)
    clinician.save!
  end
end

# Each clinician gets a few available slots over the next few days.
slot_seeds = [
  # Dr. Sam Clinician
  create_slot_seed("c1000000-0000-4000-8000-000000000001", CLINICIANS[0][:id], 1, 9, 30),
  create_slot_seed("c1000000-0000-4000-8000-000000000002", CLINICIANS[0][:id], 1, 10, 30),
  create_slot_seed("c1000000-0000-4000-8000-000000000003", CLINICIANS[0][:id], 1, 14, 30),
  create_slot_seed("c1000000-0000-4000-8000-000000000004", CLINICIANS[0][:id], 2, 9, 30),
  create_slot_seed("c1000000-0000-4000-8000-000000000005", CLINICIANS[0][:id], 2, 11, 30),
  create_slot_seed("c1000000-0000-4000-8000-000000000006", CLINICIANS[0][:id], 3, 15, 30),

  # Dr. Ada Clinician
  create_slot_seed("c1000000-0000-4000-8000-000000000007", CLINICIANS[1][:id], 1, 11, 30),
  create_slot_seed("c1000000-0000-4000-8000-000000000008", CLINICIANS[1][:id], 2, 13, 30),
  create_slot_seed("c1000000-0000-4000-8000-000000000009", CLINICIANS[1][:id], 3, 10, 30),

  # Dr. Jordan Lee
  create_slot_seed("c1000000-0000-4000-8000-000000000010", CLINICIANS[2][:id], 1, 8, 30),
  create_slot_seed("c1000000-0000-4000-8000-000000000011", CLINICIANS[2][:id], 1, 16, 30),
  create_slot_seed("c1000000-0000-4000-8000-000000000012", CLINICIANS[2][:id], 2, 12, 30),

  # Dr. Priya Shah
  create_slot_seed("c1000000-0000-4000-8000-000000000013", CLINICIANS[3][:id], 1, 13, 30),
  create_slot_seed("c1000000-0000-4000-8000-000000000014", CLINICIANS[3][:id], 2, 10, 30),
  create_slot_seed("c1000000-0000-4000-8000-000000000015", CLINICIANS[3][:id], 3, 9, 30),

  # Dr. Morgan Ellis
  create_slot_seed("c1000000-0000-4000-8000-000000000016", CLINICIANS[4][:id], 1, 15, 30),
  create_slot_seed("c1000000-0000-4000-8000-000000000017", CLINICIANS[4][:id], 2, 14, 30),
  create_slot_seed("c1000000-0000-4000-8000-000000000018", CLINICIANS[4][:id], 3, 11, 30)
]

Patient.find_or_initialize_by(id: DEFAULT_PATIENT_ID).tap do |patient|
  patient.name = "Alex Patient"
  patient.email = "alex@example.com"
  patient.save!
end

upsert_clinician!(ADMIN)
CLINICIANS.each { |attrs| upsert_clinician!(attrs) }

slot_seeds.each do |attrs|
  Slot.find_or_initialize_by(id: attrs[:id]).tap do |slot|
    slot.assign_attributes(attrs)
    slot.save!
  end
end

puts "Seeded patient-booking-rails database"
puts "VITE_DEFAULT_PATIENT_ID=#{DEFAULT_PATIENT_ID}"
puts "VITE_DEFAULT_CLINICIAN_ID=#{DEFAULT_CLINICIAN_NAME}"
puts "Login (clinician): email=#{CLINICIANS.first[:email]} password=#{DEFAULT_PASSWORD}"
puts "Login (admin): email=#{ADMIN[:email]} password=#{ADMIN_PASSWORD}"
puts "Clinicians:"
CLINICIANS.each { |clinician| puts "  - #{clinician[:name]}" }
