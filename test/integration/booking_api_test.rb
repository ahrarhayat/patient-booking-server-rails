require "test_helper"

class HealthControllerTest < ActionDispatch::IntegrationTest
  test "returns ok when database is connected" do
    get "/health"

    assert_response :success
    assert_equal({ "status" => "ok", "database" => "connected" }, JSON.parse(response.body))
  end
end

class AuthApiTest < ActionDispatch::IntegrationTest
  setup do
    uid = SecureRandom.hex(4)
    @clinician = Clinician.create!(
      name: "Dr. Sam Auth #{uid}",
      email: "sam-auth-#{uid}@clinic.example.com",
      password: "password123",
      role: :clinician
    )
    @admin = Clinician.create!(
      name: "Admin Auth #{uid}",
      email: "admin-auth-#{uid}@clinic.example.com",
      password: "admin123",
      role: :admin
    )
  end

  test "logs in with clinician email and password" do
    post "/auth/login", params: { email: @clinician.email, password: "password123" }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert body["token"].present?
    assert_equal @clinician.name, body["clinician"]["name"]
    assert_equal @clinician.email, body["clinician"]["email"]
    assert_equal "clinician", body["clinician"]["role"]
  end

  test "rejects invalid credentials" do
    post "/auth/login", params: { email: @clinician.email, password: "wrong-password" }, as: :json

    assert_response :unauthorized
    assert_equal "invalid email or password", JSON.parse(response.body)["message"]
  end

  test "returns current clinician for valid token" do
    token = AuthToken.issue(@admin)

    get "/auth/me", headers: { "Authorization" => "Bearer #{token}" }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal @admin.name, body["name"]
    assert_equal "admin", body["role"]
  end

  test "admin can create a clinician" do
    token = AuthToken.issue(@admin)
    uid = SecureRandom.hex(4)
    name = "Dr. New Clinician #{uid}"
    email = "new-#{uid}@clinic.example.com"

    post "/clinicians",
         params: {
           name: name,
           email: email,
           password: "password123"
         },
         headers: { "Authorization" => "Bearer #{token}" },
         as: :json

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal name, body["name"]
    assert_equal email, body["email"]
    assert_equal "clinician", body["role"]
    assert Clinician.exists?(name: name)
  end

  test "clinician cannot create a clinician" do
    token = AuthToken.issue(@clinician)
    uid = SecureRandom.hex(4)

    post "/clinicians",
         params: {
           name: "Dr. New Clinician #{uid}",
           email: "new-#{uid}@clinic.example.com",
           password: "password123"
         },
         headers: { "Authorization" => "Bearer #{token}" },
         as: :json

    assert_response :forbidden
  end

  test "create clinician requires auth" do
    uid = SecureRandom.hex(4)

    post "/clinicians",
         params: {
           name: "Dr. New Clinician #{uid}",
           email: "new-#{uid}@clinic.example.com",
           password: "password123"
         },
         as: :json

    assert_response :unauthorized
  end
end

class BookingApiTest < ActionDispatch::IntegrationTest
  setup do
    uid = SecureRandom.hex(4)
    @patient = Patient.create!(name: "Alex", email: "alex-#{uid}@example.com")
    @clinician = Clinician.create!(
      name: "Dr. Sam #{uid}",
      email: "sam-#{uid}@clinic.example.com",
      password: "password123",
      role: :clinician
    )
    @other_clinician = Clinician.create!(
      name: "Dr. Ada #{uid}",
      email: "ada-#{uid}@clinic.example.com",
      password: "password123",
      role: :clinician
    )
    @admin = Clinician.create!(
      name: "Admin #{uid}",
      email: "admin-#{uid}@clinic.example.com",
      password: "admin123",
      role: :admin
    )
    @slot = Slot.create!(
      clinician: @clinician,
      start_time: 1.day.from_now.change(hour: 9),
      end_time: 1.day.from_now.change(hour: 9, min: 30),
      is_available: true,
      version: 0
    )
    @other_slot = Slot.create!(
      clinician: @other_clinician,
      start_time: 1.day.from_now.change(hour: 11),
      end_time: 1.day.from_now.change(hour: 11, min: 30),
      is_available: true,
      version: 0
    )
    @clinician_token = AuthToken.issue(@clinician)
    @admin_token = AuthToken.issue(@admin)
  end

  def auth_headers(token)
    { "Authorization" => "Bearer #{token}" }
  end

  test "lists bookable clinicians without admin" do
    get "/clinicians"

    assert_response :success
    body = JSON.parse(response.body)
    names = body.map { |item| item["name"] }
    assert_includes names, @clinician.name
    assert_includes names, @other_clinician.name
    assert_not_includes names, @admin.name
  end

  test "lists available clinician slots" do
    get "/clinicians/#{ERB::Util.url_encode(@clinician.name)}/slots",
        params: { from: Time.current.iso8601, to: 7.days.from_now.iso8601 }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.length
    assert_equal @slot.id, body.first["id"]
    assert_equal @clinician.id, body.first["clinicianId"]
    assert_equal @clinician.name, body.first["clinicianName"]
  end

  test "returns not found for unknown clinician name" do
    get "/clinicians/#{ERB::Util.url_encode("Unknown Clinician")}/slots",
        params: { from: Time.current.iso8601, to: 7.days.from_now.iso8601 }

    assert_response :not_found
    assert_equal "clinician not found", JSON.parse(response.body)["message"]
  end

  test "requires slot range query params" do
    get "/clinicians/#{ERB::Util.url_encode(@clinician.name)}/slots"

    assert_response :bad_request
  end

  test "requires auth to book an appointment" do
    post "/appointments", params: { patientId: @patient.id, slotId: @slot.id }, as: :json

    assert_response :unauthorized
  end

  test "lists patients for authenticated staff" do
    get "/patients", headers: auth_headers(@clinician_token)

    assert_response :success
    body = JSON.parse(response.body)
    found = body.find { |item| item["id"] == @patient.id }
    assert found, "expected patient #{@patient.id} in list"
    assert_equal @patient.name, found["name"]
    assert_equal @patient.email, found["email"]
  end

  test "requires auth to list patients" do
    get "/patients"

    assert_response :unauthorized
  end

  test "creates a patient" do
    email = "jamie-#{SecureRandom.hex(4)}@example.com"

    post "/patients",
         params: { name: "Jamie Patient", email: email },
         headers: auth_headers(@clinician_token),
         as: :json

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "Jamie Patient", body["name"]
    assert_equal email, body["email"]
    assert body["id"].present?
    assert Patient.exists?(id: body["id"], name: "Jamie Patient")
  end

  test "rejects duplicate patient email" do
    post "/patients",
         params: { name: "Alex Duplicate", email: @patient.email },
         headers: auth_headers(@clinician_token),
         as: :json

    assert_response :bad_request
  end

  test "clinician books an appointment on own slot" do
    post "/appointments",
         params: { patientId: @patient.id, slotId: @slot.id },
         headers: auth_headers(@clinician_token),
         as: :json

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal @patient.id, body["patientId"]
    assert_equal @patient.name, body["patientName"]
    assert_equal @slot.id, body["slotId"]
    assert_equal false, body["slot"]["isAvailable"]
    assert_not @slot.reload.is_available
  end

  test "clinician cannot book another clinician slot" do
    post "/appointments",
         params: { patientId: @patient.id, slotId: @other_slot.id },
         headers: auth_headers(@clinician_token),
         as: :json

    assert_response :forbidden
  end

  test "admin can book any clinician slot" do
    post "/appointments",
         params: { patientId: @patient.id, slotId: @other_slot.id },
         headers: auth_headers(@admin_token),
         as: :json

    assert_response :created
    assert_not @other_slot.reload.is_available
  end

  test "returns conflict when slot is unavailable" do
    @slot.update!(is_available: false)

    post "/appointments",
         params: { patientId: @patient.id, slotId: @slot.id },
         headers: auth_headers(@clinician_token),
         as: :json

    assert_response :conflict
    assert_equal "slot no longer available", JSON.parse(response.body)["message"]
  end

  test "cancels an appointment" do
    appointment = Appointment.create!(patient: @patient, slot: @slot)
    @slot.update!(is_available: false)

    delete "/appointments/#{appointment.id}", headers: auth_headers(@clinician_token)

    assert_response :no_content
    assert @slot.reload.is_available
  end

  test "clinician cannot cancel another clinician appointment" do
    appointment = Appointment.create!(patient: @patient, slot: @other_slot)
    @other_slot.update!(is_available: false)

    delete "/appointments/#{appointment.id}", headers: auth_headers(@clinician_token)

    assert_response :forbidden
  end

  test "admin lists all appointments" do
    own = Appointment.create!(patient: @patient, slot: @slot)
    other = Appointment.create!(patient: @patient, slot: @other_slot)
    @slot.update!(is_available: false)
    @other_slot.update!(is_available: false)

    get "/appointments", headers: auth_headers(@admin_token)

    assert_response :success
    ids = JSON.parse(response.body).map { |item| item["id"] }
    assert_includes ids, own.id
    assert_includes ids, other.id
  end

  test "clinician lists only own appointments" do
    own = Appointment.create!(patient: @patient, slot: @slot)
    Appointment.create!(patient: @patient, slot: @other_slot)
    @slot.update!(is_available: false)
    @other_slot.update!(is_available: false)

    get "/appointments", headers: auth_headers(@clinician_token)

    assert_response :success
    ids = JSON.parse(response.body).map { |item| item["id"] }
    assert_equal [ own.id ], ids
  end

  test "lists patient appointments for authorized clinician" do
    appointment = Appointment.create!(patient: @patient, slot: @slot)
    @slot.update!(is_available: false)

    get "/patients/#{@patient.id}/appointments", headers: auth_headers(@clinician_token)

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.length
    assert_equal appointment.id, body.first["id"]
  end

  test "returns 404 for unknown routes" do
    get "/does-not-exist"

    assert_response :not_found
    assert_equal "Route not found: GET /does-not-exist", JSON.parse(response.body)["message"]
  end
end
