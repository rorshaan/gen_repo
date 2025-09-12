class AddImportFileIdToChannelOnes < ActiveRecord::Migration[7.0]
  def change
    add_column :channel_ones, :import_file_id, :integer
    add_index :channel_ones, :import_file_id
  end
end
