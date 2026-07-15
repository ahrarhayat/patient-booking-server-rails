require "test_helper"

class HealthControllerTest < ActionDispatch::IntegrationTest
  test "returns ok when database is connected" do
    get "/health"

    assert_response :success
    assert_equal({ "status" => "ok", "database" => "connected" }, JSON.parse(response.body))
  end
end

class BookingApiTest < ActionDispatch::IntegrationTest
  setup do
    @patient = Patient.create!(id: "a0000000-0000-4000-8000-000000000001", name: "Alex", email: "alex@example.com")
    @clinician = Clinician.create!(id: "b0000000-0000-4000-8000-000000000001", name: "Dr. Sam", email: "sam@clinic.example.com")
    @slot = Slot.create!(
      id: "c1000000-0000-4000-8000-000000000001",
      clinician: @clinician,
      start_time: 1.day.from_now.change(hour: 9),
      end_time: 1.day.from_now.change(hour: 9, min: 30),
      is_available: true,
      version: 0
    )
  end

  test "lists clinicians" do
    other = Clinician.create!(name: "Dr. Ada", email: "ada@clinic.example.com")

    get "/clinicians"

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal [ other.name, @clinician.name ].sort, body.map { |item| item["name"] }.sort
    assert_equal @clinician.id, body.find { |item| item["name"] == @clinician.name }["id"]
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

  test "books an appointment" do
    post "/appointments", params: { patientId: @patient.id, slotId: @slot.id }, as: :json

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal @patient.id, body["patientId"]
    assert_equal @slot.id, body["slotId"]
    assert_equal false, body["slot"]["isAvailable"]
    assert_not @slot.reload.is_available
  end

  test "returns conflict when slot is unavailable" do
    @slot.update!(is_available: false)

    post "/appointments", params: { patientId: @patient.id, slotId: @slot.id }, as: :json

    assert_response :conflict
    assert_equal "slot no longer available", JSON.parse(response.body)["message"]
  end

  test "cancels an appointment" do
    appointment = Appointment.create!(patient: @patient, slot: @slot)
    @slot.update!(is_available: false)

    delete "/appointments/#{appointment.id}"

    assert_response :no_content
    assert @slot.reload.is_available
  end

  test "lists patient appointments" do
    appointment = Appointment.create!(patient: @patient, slot: @slot)
    @slot.update!(is_available: false)

    get "/patients/#{@patient.id}/appointments"

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
