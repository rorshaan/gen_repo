class AddImportStatsToImportFiles < ActiveRecord::Migration[7.0]
  def change
    add_column :import_files, :total_rows, :integer
    add_column :import_files, :processed_count, :integer
    add_column :import_files, :rejected_count, :integer
    add_column :import_files, :error_file_path, :string
  end
end
