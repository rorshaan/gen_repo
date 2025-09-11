class CreateImportFiles < ActiveRecord::Migration[7.0]
  def change
    create_table :import_files do |t|
      t.references :user, null: false, foreign_key: true
      t.string :model_name
      t.string :file_path
      t.string :status, default: "pending"
      t.string :job_id

      t.timestamps
    end
  end
end
