class AddImportFileToChannelTransactions < ActiveRecord::Migration[7.0]
  def change
    add_reference :channel_transactions, :import_file, null: false, foreign_key: true
  end
end
