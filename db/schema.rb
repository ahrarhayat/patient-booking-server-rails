# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_15_070000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "patient_id", null: false
    t.uuid "slot_id", null: false
    t.datetime "updated_at", null: false
    t.index ["patient_id"], name: "index_appointments_on_patient_id"
    t.index ["slot_id"], name: "index_appointments_on_slot_id", unique: true
  end

  create_table "clinicians", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.string "role", default: "clinician", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_clinicians_on_email", unique: true
    t.index ["name"], name: "index_clinicians_on_name", unique: true
    t.index ["role"], name: "index_clinicians_on_role"
  end

  create_table "patients", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_patients_on_email", unique: true
  end

  create_table "slots", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "clinician_id", null: false
    t.datetime "created_at", null: false
    t.datetime "end_time", null: false
    t.boolean "is_available", default: true, null: false
    t.datetime "start_time", null: false
    t.datetime "updated_at", null: false
    t.integer "version", default: 0, null: false
    t.index ["clinician_id", "start_time"], name: "index_slots_on_clinician_id_and_start_time"
    t.index ["clinician_id"], name: "index_slots_on_clinician_id"
  end

  add_foreign_key "appointments", "patients"
  add_foreign_key "appointments", "slots"
  add_foreign_key "slots", "clinicians"
end
