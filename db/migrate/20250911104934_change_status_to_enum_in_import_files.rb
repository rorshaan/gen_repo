class ChangeStatusToEnumInImportFiles < ActiveRecord::Migration[7.0]
  def change
    remove_column :import_files, :status, :string
    add_column :import_files, :status, :integer, default: 0, null: false
  end
end
