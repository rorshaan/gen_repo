class AddTransactionCategoryToChannelTransactions < ActiveRecord::Migration[7.0]
  def change
    add_column :channel_transactions, :transaction_category, :string
  end
end
