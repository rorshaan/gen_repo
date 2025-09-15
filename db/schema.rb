# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2025_09_12_130102) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "channel_ones", force: :cascade do |t|
    t.string "transaction_id"
    t.string "sender_msisdn"
    t.decimal "transaction_amount"
    t.datetime "transaction_datetime"
    t.string "transaction_type"
    t.string "receiver_msisdn"
    t.string "service_name"
    t.string "transaction_status"
    t.string "reference_number"
    t.decimal "previous_balance"
    t.decimal "post_balance"
    t.string "external_transaction_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "import_file_id"
    t.index ["import_file_id"], name: "index_channel_ones_on_import_file_id"
  end

  create_table "channel_twos", force: :cascade do |t|
    t.string "receipt_no"
    t.datetime "completion_time"
    t.datetime "initiation_time"
    t.string "details"
    t.string "transaction_status"
    t.string "currency"
    t.string "paid_in"
    t.decimal "withdrawn"
    t.decimal "balance"
    t.string "reason_type"
    t.string "opposite_party"
    t.string "linked_transaction_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "import_file_id"
    t.index ["import_file_id"], name: "index_channel_twos_on_import_file_id"
  end

  create_table "import_files", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "channel_name"
    t.string "file_path"
    t.string "job_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0, null: false
    t.integer "total_rows"
    t.integer "processed_count"
    t.integer "rejected_count"
    t.string "error_file_path"
    t.index ["user_id"], name: "index_import_files_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "import_files", "users"
end
