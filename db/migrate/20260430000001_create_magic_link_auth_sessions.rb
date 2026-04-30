class CreateMagicLinkAuthSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :magic_link_auth_sessions do |t|
      t.references :user, null: false, foreign_key: { to_table: :users }
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end
  end
end
