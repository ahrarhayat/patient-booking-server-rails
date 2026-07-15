class AddAuthToClinicians < ActiveRecord::Migration[8.1]
  def change
    add_column :clinicians, :password_digest, :string, null: false, default: ""
    add_column :clinicians, :role, :string, null: false, default: "clinician"
    add_index :clinicians, :role

    change_column_default :clinicians, :password_digest, from: "", to: nil
  end
end
