class CreateMagicLinkAuthTokenDenylists < ActiveRecord::Migration[8.1]
  def change
    create_table :magic_link_auth_token_denylists do |t|
      t.text :jti, null: false
      t.datetime :exp, null: false

      t.timestamps
    end

    add_index :magic_link_auth_token_denylists, :jti, unique: true
  end
end
