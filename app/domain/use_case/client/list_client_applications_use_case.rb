# frozen_string_literal: true

class UseCase::Client::ListClientApplicationsUseCase
  ALLOWED_FIELDS = %w[id name protocol entity_id acs_url active created_at updated_at].freeze

  def initialize(client_repo: ClientApplication)
    @client_repo = client_repo
  end

  # @param [String] organization_id
  # @param [Array<String>] fields
  # @return [ActiveRecord::Relation]
  def call(organization_id:, fields: [])
    selected = Array(fields).map(&:to_s) & ALLOWED_FIELDS
    selected = ALLOWED_FIELDS if selected.empty?

    @client_repo.for_organization(organization_id).select(selected).order(:name)
  end
end
