class CreateChannelTransactions < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_transactions do |t|
      t.string :type, null: false # STI Column

      # Comman Field in Channels 
      t.string :transaction_status # 1,2,4 & 5 
      t.decimal :previous_balance # 1,4,3 & 6
      t.decimal :post_balance # 1,4,3 & 6
      t.string :reference_number # 1,4,3 & 6

      # Channel 1 & 4
      t.string :transaction_id
      t.string :sender_msisdn
      t.decimal :transaction_amount
      t.datetime :transaction_datetime
      t.string :transaction_type
      t.string :receiver_msisdn
      t.string :service_name
      t.string :external_transaction_id

      # Channel 2 & 5
      t.string :receipt_no
      t.datetime :completion_time
      t.datetime :initiation_time
      t.string :details
      t.string :currency
      t.string :paid_in
      t.decimal :withdrawn
      t.decimal :balance
      t.string :reason_type
      t.string :opposite_party
      t.string :linked_transaction_id

      # Channel 3 & 6
      t.string :transfer_id
      t.datetime :transfer_date
      t.decimal :amount
      t.string :transfer_status
      t.decimal :money_payer_receiver
      t.string :account
      t.datetime :status_change_date
      t.decimal :original_txn_id

      t.timestamps
    end

    add_index :channel_transactions, :type
    add_index :channel_transactions, :transaction_id
    add_index :channel_transactions, :receipt_no
    add_index :channel_transactions, :transfer_id
  end
end
