class AddUniqueIndexToClinicianNames < ActiveRecord::Migration[8.1]
  def change
    add_index :clinicians, :name, unique: true unless index_exists?(:clinicians, :name, unique: true)
  end
end
