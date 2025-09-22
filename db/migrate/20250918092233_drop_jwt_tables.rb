class DropJwtTables < ActiveRecord::Migration[7.0]
  def change
    drop_table :jwt_deny_lists, if_exists: true
    drop_table :jwt_denylists, if_exists: true
  end
end
