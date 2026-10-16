# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :users, [:organization_id, :email], unique: true
  end
end
