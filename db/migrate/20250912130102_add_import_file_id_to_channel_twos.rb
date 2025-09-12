class AddImportFileIdToChannelTwos < ActiveRecord::Migration[7.0]
  def change
    add_column :channel_twos, :import_file_id, :integer
    add_index :channel_twos, :import_file_id
  end
end
