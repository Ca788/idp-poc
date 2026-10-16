# frozen_string_literal: true

# == Schema Information
#
# Table name: identity_sessions
#
#  id              :uuid             not null, primary key
#  expires_at      :datetime         not null
#  token_digest    :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :uuid             not null
#  user_id         :uuid             not null
#
# Indexes
#
#  index_identity_sessions_on_organization_id  (organization_id)
#  index_identity_sessions_on_token_digest     (token_digest) UNIQUE
#  index_identity_sessions_on_user_id          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (user_id => users.id)
#
class IdentitySession < ApplicationRecord
  include OrgScoped

  belongs_to :user

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where("expires_at > ?", Time.current) }

  def self.digest(token)
    Digest::SHA256.hexdigest(token)
  end
end
