class CreateChannelOnes < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_ones do |t|
      t.string :transaction_id
      t.string :sender_msisdn
      t.decimal :transaction_amount
      t.datetime :transaction_datetime
      t.string :transaction_type
      t.string :receiver_msisdn
      t.string :service_name
      t.string :transaction_status
      t.string :reference_number
      t.decimal :previous_balance
      t.decimal :post_balance
      t.string :external_transaction_id

      t.timestamps
    end
  end
end
