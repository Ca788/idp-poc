# frozen_string_literal: true

class CreateIdentitySessions < ActiveRecord::Migration[8.1]
  def change
    create_table :identity_sessions, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.timestamps
    end

    add_index :identity_sessions, :token_digest, unique: true
  end
end
