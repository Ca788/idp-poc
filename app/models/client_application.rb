# frozen_string_literal: true

# == Schema Information
#
# Table name: client_applications
#
#  id              :uuid             not null, primary key
#  acs_url         :string           not null
#  active          :boolean          default(TRUE), not null
#  name            :string           not null
#  protocol        :string           not null
#  sp_certificate  :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  entity_id       :string           not null
#  organization_id :uuid             not null
#
# Indexes
#
#  index_client_applications_on_organization_id                (organization_id)
#  index_client_applications_on_organization_id_and_entity_id  (organization_id,entity_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#
class ClientApplication < ApplicationRecord
  include OrgScoped

  PROTOCOLS = %w[saml oidc].freeze

  validates :name, presence: true
  validates :protocol, presence: true, inclusion: { in: PROTOCOLS }
  validates :entity_id, presence: true, uniqueness: { scope: :organization_id }
  validates :acs_url, presence: true
end
