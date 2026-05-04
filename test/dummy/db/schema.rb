ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :email, null: false
    t.timestamps
  end
  add_index :users, :email, unique: true

  create_table :magic_link_auth_sessions, force: true do |t|
    t.references :user, null: false
    t.string :ip_address
    t.string :user_agent
    t.timestamps
  end

  create_table :magic_link_auth_token_denylists, force: true do |t|
    t.text :jti, null: false
    t.datetime :exp, null: false
    t.timestamps
  end
  add_index :magic_link_auth_token_denylists, :jti, unique: true
end
