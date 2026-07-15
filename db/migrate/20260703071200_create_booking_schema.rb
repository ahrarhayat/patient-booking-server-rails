class CreateBookingSchema < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    create_table :patients, id: :uuid do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.timestamps
    end
    add_index :patients, :email, unique: true

    create_table :clinicians, id: :uuid do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.timestamps
    end
    add_index :clinicians, :name, unique: true
    add_index :clinicians, :email, unique: true

    create_table :slots, id: :uuid do |t|
      t.references :clinician, null: false, foreign_key: true, type: :uuid
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.boolean :is_available, null: false, default: true
      t.integer :version, null: false, default: 0
      t.timestamps
    end
    add_index :slots, [ :clinician_id, :start_time ]

    create_table :appointments, id: :uuid do |t|
      t.references :patient, null: false, foreign_key: true, type: :uuid
      t.references :slot, null: false, foreign_key: true, type: :uuid, index: { unique: true }
      t.timestamps
    end
  end
end
