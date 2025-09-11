class CreateChannelTwos < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_twos do |t|
      t.string :receipt_no
      t.datetime :completion_time
      t.datetime :initiation_time
      t.string :details
      t.string :transaction_status
      t.string :currency
      t.string :paid_in
      t.decimal :withdrawn
      t.decimal :balance
      t.string :reason_type
      t.string :opposite_party
      t.string :linked_transaction_id

      t.timestamps
    end
  end
end
