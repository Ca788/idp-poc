# frozen_string_literal: true

class CreateClientApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :client_applications, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :protocol, null: false
      t.string :entity_id, null: false
      t.string :acs_url, null: false
      t.text :sp_certificate
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :client_applications, [:organization_id, :entity_id], unique: true
  end
end
