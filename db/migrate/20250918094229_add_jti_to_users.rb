class AddJtiToUsers < ActiveRecord::Migration[6.1]
  def up
    # Step 1: add column without NOT NULL
    add_column :users, :jti, :string

    # Step 2: backfill existing rows with unique values
    User.reset_column_information
    User.find_each do |user|
      user.update_columns(jti: SecureRandom.uuid)
    end

    # Step 3: enforce NOT NULL + add index
    change_column_null :users, :jti, false
    add_index :users, :jti, unique: true
  end

  def down
    remove_index :users, :jti
    remove_column :users, :jti
  end
end
