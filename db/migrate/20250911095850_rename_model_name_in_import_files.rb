class RenameModelNameInImportFiles < ActiveRecord::Migration[7.0]
  def change
    rename_column :import_files, :model_name, :channel_name
  end
end
